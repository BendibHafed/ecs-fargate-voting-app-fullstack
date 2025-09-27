import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { API_URL } from "../api";
import "../styles/Login.css";

function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [regEmail, setRegEmail] = useState("");
  const [regPassword, setRegPassword] = useState("");
  const [showRegister, setShowRegister] = useState(false);
  const navigate = useNavigate();

  const login = async () => {
    const res = await fetch(`${API_URL}/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password }),
    });
    if (res.ok) {
      const data = await res.json();
      localStorage.setItem("user_token", data.token);
      localStorage.setItem("user_email", data.email);
      navigate("/vote");
    } else {
      alert("Login failed!");
    }
  };

  const register = async () => {
    const res = await fetch(`${API_URL}/register`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: regEmail, password: regPassword }),
    });
    if (res.ok) {
      const data = await res.json();
      localStorage.setItem("user_email", data.email);
      navigate("/vote");
    } else {
      alert("Registration failed");
    }
  };

  return (
    <div className="auth-container">
      {!showRegister ? (
        <>
          <h1>Login</h1>
          <input
            onChange={(e) => setEmail(e.target.value)}
            type="email"
            placeholder="Email"
            value={email}
          />
          <input
            onChange={(e) => setPassword(e.target.value)}
            type="password"
            placeholder="Password"
            value={password}
          />
          <button onClick={login}>Login</button>
          <button onClick={() => setShowRegister(true)}>Register</button>
        </>
      ) : (
        <div className="register-section">
          <h2>Register</h2>
          <input
            onChange={(e) => setRegEmail(e.target.value)}
            type="email"
            placeholder="Email"
            value={regEmail}
          />
          <input
            onChange={(e) => setRegPassword(e.target.value)}
            type="password"
            placeholder="Password"
            value={regPassword}
          />
          <button onClick={register}>Submit</button>
          <button onClick={() => setShowRegister(false)}>Back to Login</button>
        </div>
      )}
    </div>
  );
}

export default Login;
