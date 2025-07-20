import express from 'express';
import {
    createCompany,
    fetchCompanies,
    getCompany
} from "../controllers/companyController.js";

const router = express.Router();

router.post('/', createCompany);

router.get('/', fetchCompanies);

router.get('/:name', getCompany);

export default router;
