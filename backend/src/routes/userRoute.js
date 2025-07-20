import express from 'express';
import {
    createUser,
    fetchSubscriptions,
    cancelSubscription,
    enrollSubscription
} from "../controllers/userController.js";

const router = express.Router();

router.post('/', createUser);

router.get('/:walletAddress/subscriptions', fetchSubscriptions);

router.post('/:walletAddress/enroll', enrollSubscription);

router.post('/:walletAddress/cancel', cancelSubscription);

export default router;