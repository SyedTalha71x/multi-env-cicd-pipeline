import dotenv from "dotenv";
import mongoose from "mongoose";
import logger from "./logger.js";

dotenv.config({ path: process.env.NODE_ENV === "test" ? ".env.test" : ".env" });

const MONGODB_URI = process.env.MONGODB_URI;

// console.log(`Connecting to MongoDB at ${MONGODB_URI}`);
logger.info(`Connecting to MongoDB at ${MONGODB_URI}`);

export const connectDatabase = async () => {
  try {
    await mongoose.connect(MONGODB_URI);

    logger.info("MongoDB connected successfully");

    mongoose.connection.on("error", (err) => {
      logger.error("MongoDB connection error:", err);
    });

    mongoose.connection.on("disconnected", () => {
      logger.warn("MongoDB disconnected");
    });

    process.on("SIGINT", async () => {
      await mongoose.connection.close();
      logger.info("MongoDB connection closed through app termination");
      process.exit(0);
    });
  } catch (error) {
    logger.error("MongoDB connection failed:", error);
    process.exit(1);
  }
};

export default mongoose;
