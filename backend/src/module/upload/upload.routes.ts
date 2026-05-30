import { Router } from 'express';
import { requireAuth } from '@/middleware/auth.middleware';
import { uploadImage, uploadDocument } from '@/middleware/upload.middleware';
import { uploadController } from '@/module/upload/upload.controller';

const router = Router();

router.use(requireAuth);

router.post('/image', uploadImage.single('image'), uploadController.uploadImage);
router.post('/images', uploadImage.array('images', 10), uploadController.uploadImages);
router.post('/document', uploadDocument.single('document'), uploadController.uploadDocument);
router.post('/avatar', uploadImage.single('avatar'), uploadController.uploadAvatar);

export default router;
