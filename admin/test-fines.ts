import { syncOverdueLoanFines } from "./lib/firebase/library-data";

syncOverdueLoanFines()
  .then(() => console.log("Success"))
  .catch((error) => console.error("Error:", error));
