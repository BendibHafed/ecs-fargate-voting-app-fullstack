import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import Login from "./pages/Login.jsx";
import Vote from "./pages/Vote.jsx";

function App() {
  return (
    <>
      <Router>
        <Routes>
          <Route path="/" element={<Login />} />
          <Route path="/vote" element={<Vote />} />
          <Route />
        </Routes>
      </Router>
    </>
  );
}

export default App;
