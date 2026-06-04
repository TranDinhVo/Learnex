/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}", // Nếu dùng App Router
    "./pages/**/*.{js,ts,jsx,tsx,mdx}", // Nếu dùng Pages Router
    "./components/**/*.{js,ts,jsx,tsx,mdx}",

    // Hoặc nếu toàn bộ nằm trong thư mục /src:
    "./src/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
};
