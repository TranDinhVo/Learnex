import { AppError } from "../utils/AppError";
// pdf-parse is a CommonJS module — must use require()
// eslint-disable-next-line @typescript-eslint/no-require-imports
const pdfParse = require("pdf-parse") as (
  buffer: Buffer,
) => Promise<{ text: string }>;
// eslint-disable-next-line @typescript-eslint/no-require-imports
const mammoth = require("mammoth");

interface GroqMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

interface ChatOptions {
  documentTitle: string;
  documentDescription: string;
  documentSubject: string;
  fileUrl?: string;
  messages: { role: "user" | "assistant"; content: string }[];
}

class GroqService {
  private readonly apiUrl = "https://api.groq.com/openai/v1/chat/completions";
  private readonly model = "llama-3.3-70b-versatile";
  // Simple in-memory cache for extracted document text (keyed by fileUrl)
  private readonly _contentCache = new Map<string, string>();

  /**
   * Fetch and extract text content from a document URL.
   * Supports PDF. Falls back to empty string for unsupported formats.
   */
  private async extractFileContent(fileUrl: string): Promise<string> {
    if (!fileUrl) return "";

    // Check cache first
    if (this._contentCache.has(fileUrl)) {
      return this._contentCache.get(fileUrl)!;
    }

    try {
      const response = await fetch(fileUrl);
      if (!response.ok) return "";

      const contentType = response.headers.get("content-type") ?? "";
      const isPdf =
        fileUrl.toLowerCase().includes(".pdf") || contentType.includes("pdf");
      const isDocx =
        fileUrl.toLowerCase().includes(".docx") ||
        contentType.includes("wordprocessingml") ||
        contentType.includes("msword");

      if (isPdf) {
        // PDF: parse with pdf-parse
        const arrayBuffer = await response.arrayBuffer();
        const buffer = Buffer.from(arrayBuffer);
        const parsed = await pdfParse(buffer);
        // Limit to first ~8000 chars to stay within token limits
        const content = parsed.text.slice(0, 8000).trim();
        this._contentCache.set(fileUrl, content);
        return content;
      } else if (isDocx) {
        // DOCX: parse with mammoth
        const arrayBuffer = await response.arrayBuffer();
        const buffer = Buffer.from(arrayBuffer);
        const parsed = await mammoth.extractRawText({ buffer });
        const content = parsed.value.slice(0, 8000).trim();
        this._contentCache.set(fileUrl, content);
        return content;
      } else {
        // For non-PDF/DOCX files, try to read as plain text (e.g. .txt, .md)
        if (contentType.includes("text")) {
          const text = await response.text();
          const trimmed = text.slice(0, 8000); // limit context size
          this._contentCache.set(fileUrl, trimmed);
          return trimmed;
        }
        return "";
      }
    } catch (err) {
      console.warn("[GroqService] Could not extract file content:", err);
      return "";
    }
  }

  async chat(options: ChatOptions): Promise<string> {
    const apiKey = process.env.GROQ_API_KEY;
    if (!apiKey) {
      throw new AppError("GROQ_API_KEY is not configured", 500);
    }

    // Try to extract actual document content
    const fileContent = options.fileUrl
      ? await this.extractFileContent(options.fileUrl)
      : "";

    const documentContextSection = fileContent
      ? `\nNội dung thực tế của tài liệu (trích đoạn đầu):\n"""\n${fileContent}\n"""`
      : `\nMô tả tài liệu: "${options.documentDescription || "Không có mô tả"}"`;

    const systemPrompt: GroqMessage = {
      role: "system",
      content: `Bạn là Learnex AI, một trợ lý học tập thông minh và thân thiện trên nền tảng Learnex.
Người dùng đang xem tài liệu có tên: "${options.documentTitle}"
Môn học: "${options.documentSubject || "Chung"}"
${documentContextSection}

Hãy trả lời các câu hỏi của học viên bằng tiếng Việt, đảm bảo:
- Ngắn gọn, dễ hiểu, trực tiếp vào vấn đề.
- Sử dụng markdown để định dạng văn bản (in đậm, danh sách, code block nếu cần).
- Nếu câu hỏi liên quan đến tài liệu, hãy cố gắng liên hệ với ngữ cảnh và nội dung của tài liệu đó.
- Nếu không biết, hãy thừa nhận và khuyến khích học viên tìm hiểu thêm.`,
    };

    // Keep last 10 messages max to stay within token limits
    const recentMessages = options.messages.slice(-10) as GroqMessage[];
    const payloadMessages = [systemPrompt, ...recentMessages];

    try {
      const response = await fetch(this.apiUrl, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: this.model,
          messages: payloadMessages,
          temperature: 0.7,
          max_tokens: 1024,
        }),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        console.error("Groq API Error:", errorData);
        throw new AppError(`Groq API error: ${response.statusText}`, 502);
      }

      const data = await response.json();
      return (
        data.choices[0]?.message?.content ||
        "Xin lỗi, tôi không thể trả lời lúc này."
      );
    } catch (error) {
      console.error("Error communicating with Groq:", error);
      if (error instanceof AppError) throw error;
      throw new AppError("Lỗi kết nối đến Learnex AI", 500);
    }
  }
}

export const groqService = new GroqService();
