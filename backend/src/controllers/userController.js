import User from "../models/User.js";

export async function createUser(req, res) {
    try {
        const {name,email,walletAddress} = req.body;
        const user = new User({
            name:name,
            walletAddress:walletAddress,
            subscriptions: [],
            email:email
        });
        const savedUser = await user.save();
        res.status(201).json(savedUser);
    } catch (error) {
        console.error("Error creating user:", error);
        res.status(500).json({ message: "Internal server error" });
    }
};

export async function fetchSubscriptions(req,res) {
    try {
                const user = await User.findOne({walletAddress:req.params.walletAddress});

        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }
        const subscriptions = user.subscriptions;
        res.status(200).json(subscriptions);
    } catch (error) {
        console.error("Error fetching subscriptions:", error);
        res.status(500).json({ message: "Internal server error" });
        
    }
}

export async function enrollSubscription(req,res){
    try {
        const subscriptionNew = req.body;
        const user = await User.findOne({walletAddress:req.params.walletAddress});
        const subscription = user.subscriptions.find(sub => sub.name === subscriptionNew.name);
        if (subscription) {
            subscription.isActive = true;
            subscription.subscriptionAddress = subscriptionNew.subscriptionAddress;
            subscription.interval = subscriptionNew.interval;
            subscription.startTime = Date.now();
            return res.status(200).json({ message: "Subscription already exists and is now active." });
        }
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }
        user.subscriptions.push(subscriptionNew);
        const updatedUser = await user.save();
        res.status(200).json(updatedUser);
    } catch (error) {
        console.error("Error enrolling subscription:", error);
        res.status(500).json({ message: "Internal server error" });
    }
}

export async function cancelSubscription(req,res){
    try{        const user = await User.findOne({walletAddress:req.params.walletAddress});

    if (!user) {
        return res.status(404).json({ message: "User not found" });
    }
    const userSubscriptions = user.subscriptions;
    const {name,method} = req.body;
    const subscription = userSubscriptions.find(sub => sub.name === name);
    if (method === "cancel") {
        subscription.isActive = false;
        const saveduser = await user.save();
        console.log(saveduser,"subscription is canceled");
    }
}catch (error) {
        console.error("Error canceling subscription:", error);
        res.status(500).json({ message: "Internal server error" });
    }
}



