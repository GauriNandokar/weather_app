🌤️ Weather Forecast App

A Ruby on Rails app that displays current and upcoming weather forecasts using the OpenWeatherMap API.
Supports both address and ZIP code lookup and caches results for 30 minutes to improve performance.

🚀 Features

Enter address or ZIP code to view weather forecast

Shows current temperature, humidity, and condition

Displays 5-day forecast (highs, lows, and descriptions)

Caches results for 30 minutes (by address or ZIP code)

Displays a note when results are served from cache

Built with HTTParty, Geocoder, and Rails caching

🧠 Example Output

Input: Delhi (By Address)

Output:

Forecast for Delhi, India

Note: This result was pulled from cache (within last 30 minutes).

Current

Temperature: 20.07 °C (feels like 19.91 °C)

Humidity: 68%

Haze - haze

Today

Low: 20.07 °C • High: 20.07 °C

Next days

2025-11-02 — Low: 20.07 °C, High: 25.06 °C. clear sky

2025-11-03 — Low: 21.4 °C, High: 32.53 °C. clear sky

2025-11-04 — Low: 24.34 °C, High: 31.96 °C. clear sky

2025-11-05 — Low: 23.25 °C, High: 31.85 °C. few clouds

2025-11-06 — Low: 21.88 °C, High: 28.51 °C. clear sky

Fetched at: 2025-11-02 20:40:20 UTC

Input: 400059 (By ZIP Code)

Output:

Forecast for 400059, Zone 6, Mumbai, Mumbai Suburban, Maharashtra, India
Note: This result was pulled from cache (within last 30 minutes).

Current
Temperature: 27.87 °C (feels like 32.22 °C)
Humidity: 83%
Haze - haze

Today
Low: 27.87 °C • High: 27.87 °C

Next days
2025-11-03 — Low: 25.38 °C, High: 27.32 °C. broken clouds
2025-11-04 — Low: 25.2 °C, High: 27.61 °C. light rain
2025-11-05 — Low: 24.65 °C, High: 27.37 °C. broken clouds
2025-11-06 — Low: 24.35 °C, High: 28.44 °C. overcast clouds
2025-11-07 — Low: 25.38 °C, High: 30.09 °C. overcast clouds

Fetched at: 2025-11-03 15:12:09 UTC


⚙️ Setup Instructions

git clone https://github.com/GauriNandokar/weather_app.git

cd weather_app

bundle install

1️⃣ Get an API Key

Visit https://openweathermap.org/api

Sign up or log in

Go to API Keys and copy your key

2️⃣ Create .env file
OPENWEATHER_API_KEY=your_api_key_here

3️⃣ Run the app
rails s


Then visit 👉 http://localhost:3000

💾 Caching

Weather data cached for 30 minutes

Cached by address or ZIP code

Enable cache in development:

rails dev:cache


⚠️ Restart the Rails server after running this command for changes to take effect.

🧪 Run Tests

bundle exec rspec

👩‍💻 Author

Gauri Nandokar

Ruby on Rails Developer
