import { AppError } from '../utils/AppError';

interface GroqMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

interface ChatOptions {
  documentTitle: string;
  documentDescription: string;
  documentSubject: string;
  messages: { role: 'user' | 'assistant'; content: string }[];
}

class GroqService {
  private readonly apiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  // Use a fast and versatile model from Groq
  private readonly model = 'llama-3.3-70b-versatile';

  async chat(options: ChatOptions): Promise<string> {
    const apiKey = process.env.GROQ_API_KEY;
    if (!apiKey) {
      throw new AppError('GROQ_API_KEY is not configured', 500);
    }

    const systemPrompt: GroqMessage = {
      role: 'system',
      content: `Bạn là Learnex AI, một trợ lý học tập thông minh và thân thiện trên nền tảng Learnex.
Người dùng đang xem tài liệu có tên: "${options.documentTitle}"
Mô tả tài liệu: "${options.documentDescription || 'Không có mô tả'}"
Môn học: "${options.documentSubject || 'Chung'}"

Hãy trả lời các câu hỏi của học viên bằng tiếng Việt, đảm bảo:
- Ngắn gọn, dễ hiểu, trực tiếp vào vấn đề.
- Sử dụng markdown để định dạng văn bản (in đậm, danh sách, code block nếu cần).
- Nếu câu hỏi liên quan đến tài liệu, hãy cố gắng liên hệ với ngữ cảnh của tài liệu đó.
- Nếu không biết, hãy thừa nhận và khuyến khích học viên tìm hiểu thêm.`,
    };

    // Ensure we don't send too many messages to stay within token limits
    // Keep last 10 messages max
    const recentMessages = options.messages.slice(-10) as GroqMessage[];

    const payloadMessages = [systemPrompt, ...recentMessages];

    try {
      const response = await fetch(this.apiUrl, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
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
        console.error('Groq API Error:', errorData);
        throw new AppError(`Groq API error: ${response.statusText}`, 502);
      }

      const data = await response.json();
      return data.choices[0]?.message?.content || 'Xin lỗi, tôi không thể trả lời lúc này.';
    } catch (error) {
      console.error('Error communicating with Groq:', error);
      if (error instanceof AppError) throw error;
      throw new AppError('Lỗi kết nối đến Learnex AI', 500);
    }
  }
}

export const groqService = new GroqService();
