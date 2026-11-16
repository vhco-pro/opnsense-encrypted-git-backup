const themeButton = document.querySelector('.theme-toggle');
const copyButton = document.querySelector('.copy-button');
const status = document.querySelector('#copy-status');
const preference = window.matchMedia('(prefers-color-scheme: dark)');

function applyTheme(theme) {
  document.documentElement.dataset.theme = theme;
  themeButton.setAttribute('aria-checked', String(theme === 'dark'));
}

let savedTheme;
try {
  savedTheme = localStorage.getItem('vhco-packages-theme');
} catch {
  // Browser privacy settings can disable preference storage.
}
applyTheme(savedTheme === 'light' || savedTheme === 'dark' ? savedTheme : preference.matches ? 'dark' : 'light');
themeButton.hidden = false;
themeButton.addEventListener('click', () => {
  const theme = document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark';
  applyTheme(theme);
  try {
    localStorage.setItem('vhco-packages-theme', theme);
  } catch {
    // The selected theme still applies for this page view.
  }
});

copyButton.hidden = false;
copyButton.addEventListener('click', async () => {
  const text = document.querySelector('#repository-url').textContent;
  try {
    await navigator.clipboard.writeText(text);
    copyButton.textContent = 'Copied';
    status.textContent = 'Repository URL copied.';
  } catch {
    const selection = window.getSelection();
    const range = document.createRange();
    range.selectNodeContents(document.querySelector('#repository-url'));
    selection.removeAllRanges();
    selection.addRange(range);
    copyButton.textContent = 'Selected';
    status.textContent = 'Select Copy on your device to copy the repository URL.';
  }
});
