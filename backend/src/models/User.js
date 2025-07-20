import mongoose from "mongoose";


const subscriptionSchema = new mongoose.Schema({
    name:{
        type: String,
        required: true,
    },
    subscriptionAddress: {
        type: String,
        required: true,
        unique: true,
    },
    price: {
        type: Number,
        required: true,
    },
    interval: {
        type: Number,
        required: true, // Duration in days
    },
    isActive: {
        type: Boolean,
        default: true,
    }
},
    {
        timestamps: true
    

});



const userSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
    },
    walletAddress: {
        type: String,
        required: true,
        unique: true,
    },
    subscriptions:[subscriptionSchema],
    email: {
        type: String,
        required: true,
        unique: true,
    }

});


const User = mongoose.model("User", userSchema);
export default User;