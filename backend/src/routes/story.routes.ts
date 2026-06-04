import { Router } from 'express';
import { storyController } from '../controllers/story.controller';
import { requireAuth } from '../middleware/auth.middleware';

const router = Router();

// All routes require authentication
router.use(requireAuth);

// Create a new story
router.post('/', storyController.createStory);

// Get feed stories (own + friends)
router.get('/feed', storyController.getFeedStories);

// Get archived stories
router.get('/archive', storyController.getArchive);

// View a story
router.post('/:id/view', storyController.viewStory);

// React to a story
router.post('/:id/react', storyController.reactStory);

// Get viewers for a story
router.get('/:id/viewers', storyController.getStoryViewers);

// Update story privacy
router.put('/:id/privacy', storyController.updateStoryPrivacy);

// Delete a story
router.delete('/:id', storyController.deleteStory);

export default router;
