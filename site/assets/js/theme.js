function checkTheme() {
    const toggle = document.getElementById("theme-toggle");
    if (!toggle) return;
    
    toggle.checked = document.documentElement.getAttribute("data-bs-theme") === "dark";
    toggle.addEventListener("change", () => {
        const theme = toggle.checked ? "dark" : "light";
        document.documentElement.setAttribute("data-bs-theme", theme);
        localStorage.setItem("theme", theme);
    });
}