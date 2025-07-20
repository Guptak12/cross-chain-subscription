import Company from "../models/Company.js";

export async function createCompany(req, res) {
    try {
        const { name, walletAddress, chainID, price } = req.body;
        const existing = await Company.findOne({ name });
        if (existing) {
            return res.status(400).json({ message: "Company with this name already exists" });
        }
        const company = new Company({
            name,
            walletAddress,
            chainID,
            price
        });
        const savedCompany = await company.save();
        console.log("Company created:", savedCompany);
        res.status(201).json(savedCompany);
    } catch (error) {
        console.error("Error creating company:", error);
        res.status(500).json({ message: "Internal server error" });
    }

}

export async function fetchCompanies(req, res) {
    try {
        const companies = await Company.find();
        res.status(200).json(companies);
    } catch (error) {
        console.error("Error fetching companies:", error);
        res.status(500).json({ message: "Internal server error" });
    }
}


export async function getCompany(req,res){
    try {
        const company = await Company.findOne({name: req.params.name});
        if (!company) {
            return res.status(404).json({ message: "Company not found" });
        }
        res.status(200).json(company);
    } catch (error) {
        console.error("Error fetching company:", error);
        res.status(500).json({ message: "Internal server error" });
    }

}