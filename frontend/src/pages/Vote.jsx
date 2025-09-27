import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { handleAuthError } from "../../utils/auth";

import "../styles/Vote.css";
import { API_URL } from "../api";

function Vote() {
  const navigate = useNavigate();
  const email = localStorage.getItem("user_email");
  const token = localStorage.getItem("user_token");
  const [polls, setPolls] = useState([]);
  const [choices, setChoices] = useState({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!email) {
      navigate("/");
    }
  }, [email, navigate]);

  useEffect(() => {
    const fetchPollsAndChoices = async () => {
      try {
        const res = await fetch(`${API_URL}/api/polls`);
        const data = await res.json();
        setPolls(data);

        const choicesMap = {};
        for (const poll of data) {
          const res = await fetch(`${API_URL}/api/polls/${poll.id}/choices`);
          const pollChoices = await res.json();
          choicesMap[poll.id] = pollChoices;
        }
        setChoices(choicesMap);
      } catch (err) {
        console.error("Error fetching polls or choices:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchPollsAndChoices();
  }, []);

  const logout = async () => {
    try {
      await fetch(`${API_URL}/logout`, { method: "POST" });
    } catch (err) {
      console.warn("Logout request failed:", err);
    }
    localStorage.removeItem("user_email");
    localStorage.removeItem("user_token");
    navigate("/");
  };

  const vote = async (pollId, choiceId) => {
    try {
      const res = await fetch(`${API_URL}/api/polls/${pollId}/vote`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ choice_id: choiceId }),
      });

      if (handleAuthError(res, navigate)) return;

      const result = await res.json();
      if (!res.ok) {
        alert(result.error || "Voting failed");
        return;
      }

      // Refresh choices for this poll
      const updated = await fetch(`${API_URL}/api/polls/${pollId}/choices`);
      const updatedChoices = await updated.json();
      setChoices((prev) => ({ ...prev, [pollId]: updatedChoices }));
    } catch (err) {
      console.error("Voting error:", err);
    }
  };

  return (
    <div className="vote-container">
      <header className="vote-header">
        <div>
          Logged in as: <strong>{email}</strong>
        </div>
        <button onClick={logout}>Logout</button>
      </header>

      <hr />
      <h1>Available Polls</h1>

      <section className="poll-section">
        {loading ? (
          <p>Loading polls...</p>
        ) : (
          polls.map((poll) => (
            <div key={poll.id} className="poll-block">
              <h2>{poll.question}</h2>
              {choices[poll.id]?.map((choice) => (
                <button
                  key={choice.id}
                  onClick={() => vote(poll.id, choice.id)}
                >
                  {choice.text} - Votes: {choice.votes}
                </button>
              ))}
            </div>
          ))
        )}
      </section>
    </div>
  );
}

export default Vote;
