function showRegister(){
  document.getElementById("register").style.display = "block";
}

async function login(){
  const email = document.getElementById("log_email").value;
  const password = document.getElementById("log_password").value;
  const r = await fetch("/login", {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({email, password})
  });
  if(r.ok){
    window.location.href = "/vote";
  } else {
    alert("Login failed");
  }
}

async function register(){
  const email = document.getElementById("reg_email").value;
  const password = document.getElementById("reg_password").value;
  const r = await fetch("/register", {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({email, password})
  });
  if(r.ok){
    // Auto-login after registration
    const login = await fetch("/login", {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({email, password})
    });
    if(login.ok) window.location.href = "/vote";
  }
}

async function logout() {
  const r = await fetch("/logout", {
    method: "POST",
    credentials: "same-origin"
  });
  if(r.ok) {
    window.location.href = "/"
  } else {
    alert("Logout failed!")
  }
}
