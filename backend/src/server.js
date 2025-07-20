import express from 'express';
import dotenv from "dotenv";
import { connectDB } from "./config/db.js";
import userRoute from "./routes/userRoute.js";
import companyRoute from "./routes/companyRoute.js";
dotenv.config();
const app = express();


app.use(express.json());

app.use("/api/user",userRoute);

app.use("/api/company",companyRoute);

connectDB().then(() => {
    app.listen(5001,()=>{
        console.log("Server is running on port 5001");
    });
});