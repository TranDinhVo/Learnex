import { Request, Response, NextFunction } from 'express';
import { groqService } from '../services/groq.service';
import { sendResponse } from '../utils/response';
import { AppError } from '../utils/AppError';

export const aiController = {
  async chat(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { documentTitle, documentDescription, documentSubject, fileUrl, messages } = req.body;

      if (!messages || !Array.isArray(messages)) {
        return next(new AppError('Messages array is required', 400));
      }

      // Basic validation of messages array
      const validMessages = messages.filter(
        (m) => m && typeof m.content === 'string' && (m.role === 'user' || m.role === 'assistant')
      );

      const reply = await groqService.chat({
        documentTitle: documentTitle || 'Tài liệu không tên',
        documentDescription: documentDescription || '',
        documentSubject: documentSubject || '',
        fileUrl: fileUrl || '',
        messages: validMessages,
      });

      sendResponse(res, 200, { reply }, 'AI replied successfully');
    } catch (error) {
      next(error);
    }
  },
};
