import { Router } from 'express';
import { requireAuth } from '../middleware/auth.middleware';
import { friendController } from '../controllers/friend.controller';

const router = Router();

router.use(requireAuth);

// Get friends list
router.get('/', friendController.getFriends);

// Get pending requests
router.get('/requests', friendController.getRequests);

// Get friendship status with a specific user
router.get('/status/:userId', friendController.getFriendshipStatus);

// Send friend request
router.post('/request/:userId', friendController.sendRequest);

// Accept friend request
router.put('/accept/:id', friendController.acceptRequest);

// Reject friend request
router.put('/reject/:id', friendController.rejectRequest);

// Unfriend
router.delete('/:userId', friendController.unfriend);

export default router;
