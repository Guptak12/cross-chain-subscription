import mongoose from "mongoose";

const companySchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
    },
    walletAddress: {
        type: String,
        required: true,
    },
    chainID: {
        type: Number,
        required: true,
    },
    price: {
        type: Number,
        required: true,
    }
});

const Company = mongoose.model("Company", companySchema);
export default Company;