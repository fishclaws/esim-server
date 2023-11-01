import axios from "axios";

export default axios.create({
  baseURL: "https://esim-gaza.org",
  headers: {
    "Content-type": "application/json",
  },
});