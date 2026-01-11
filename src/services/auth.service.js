import { configDotenv } from "dotenv";
import jwt from "jsonwebtoken";

configDotenv({
  path: process.env.NODE_ENV === "test" ? ".env.test" : ".env",
});
export const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || "1h",
  });
};

export const verifyToken = (token) => {
  try {
    return jwt.verify(token, process.env.JWT_SECRET);
  } catch (error) {
    return null;
  }
};

export const decodeToken = (token) => {
  return jwt.decode(token);
};
