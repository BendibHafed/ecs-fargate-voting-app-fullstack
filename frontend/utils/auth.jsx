export function handleAuthError(res, navigate) {
  if (res.status === 401) {
    alert("Session expired. please  log in again.");
    localStorage.removeItem("user_token");
    localStorage.removeItem("user_email");
    navigate("/");
    return true;
  }
  return false;
}
