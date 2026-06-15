# 🌱 Plant Watering App

A simple and elegant web-based application to help you track and manage your plant watering schedule.

## Features

✨ **Track Multiple Plants** - Add and manage as many plants as you want

💧 **Water Tracking** - Keep track of when each plant was last watered

⏰ **Custom Watering Intervals** - Set custom watering schedules for each plant

💾 **Persistent Storage** - Your plants data is saved locally in your browser

📱 **Responsive Design** - Works great on desktop, tablet, and mobile devices

🎨 **Beautiful UI** - Modern gradient design with smooth animations

## How to Use

1. **Open the app** - Simply open `index.html` in your web browser
2. **Add a Plant** - Enter the plant name and watering interval (in days)
3. **Water Your Plants** - Click the "💧 Water Now" button to water a plant
4. **Track Status** - See how many days it's been since each plant was watered
5. **Delete Plants** - Remove plants with the "✕" button

## Getting Started

### Quick Start

1. Clone or download this repository
2. Open `index.html` in your web browser
3. Start adding plants!

### Files

- `index.html` - Main HTML structure
- `styles.css` - Styling and layout
- `app.js` - Application logic

## Technical Details

### Plant Class

The `Plant` class manages individual plant data:
- **name** - Plant name
- **wateringInterval** - Days between waterings
- **lastWatered** - Date of last watering
- **id** - Unique identifier

### Key Methods

- `water()` - Updates the last watered date to now
- `getDaysSinceWatered()` - Calculates days since last watering
- `needsWater()` - Determines if plant needs water
- `getWaterStatus()` - Returns a user-friendly status message

### Data Storage

The app uses browser's `localStorage` to persist plant data. Your plants will be remembered even after closing and reopening the browser.

## Browser Support

- Chrome/Chromium
- Firefox
- Safari
- Edge
- Any modern browser with ES6 support

## Future Enhancements

- 📧 Email/notification reminders
- 📊 Watering history graphs
- 🎯 Plant care tips and guides
- 📸 Plant photos
- 🌍 Cloud synchronization
- 📱 Mobile app version

## License

Free to use and modify!

## Contributing

Feel free to fork, modify, and improve this app!

---

Made with 💚 for plant lovers
