import { verifyToken } from "../services/auth.service.js";
import ApiError from "../utils/ApiError.js";
import asyncHandler from "../utils/asyncHandler.js";


export const authenticate = asyncHandler(async (req, res, next) => {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new ApiError(401, 'Authentication required');
  }

  const token = authHeader.split(' ')[1];
  
  const decoded = verifyToken(token);
  if (!decoded) {
    throw new ApiError(401, 'Invalid or expired token');
  }

  req.userId = decoded.userId;
  
  next();
});

export const authorize = (...roles) => {
  return asyncHandler(async (req, res, next) => {
    // In a real app, you'd fetch user from DB and check role
    // For demo, we'll assume all authenticated users are authorized
    next();
  });
};