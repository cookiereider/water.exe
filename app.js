// Plant Watering App - Main Application Logic

class Plant {
    constructor(name, wateringInterval, lastWatered = null) {
        this.id = Date.now();
        this.name = name;
        this.wateringInterval = wateringInterval;
        this.lastWatered = lastWatered || new Date();
    }

    water() {
        this.lastWatered = new Date();
    }

    getDaysSinceWatered() {
        const now = new Date();
        const diffTime = Math.abs(now - this.lastWatered);
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        return diffDays;
    }

    needsWater() {
        return this.getDaysSinceWatered() >= this.wateringInterval;
    }

    getWaterStatus() {
        const daysSince = this.getDaysSinceWatered();
        if (daysSince === 0) {
            return 'Watered today! 💧';
        } else if (daysSince === 1) {
            return 'Watered yesterday';
        } else {
            return `Last watered ${daysSince} days ago`;
        }
    }
}

class PlantWateringApp {
    constructor() {
        this.plants = [];
        this.loadPlants();
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.render();
    }

    setupEventListeners() {
        const form = document.getElementById('plantForm');
        form.addEventListener('submit', (e) => this.addPlant(e));
    }

    addPlant(e) {
        e.preventDefault();
        
        const nameInput = document.getElementById('plantName');
        const intervalInput = document.getElementById('wateringInterval');
        
        const name = nameInput.value.trim();
        const interval = parseInt(intervalInput.value);
        
        if (name && interval > 0) {
            const plant = new Plant(name, interval);
            this.plants.push(plant);
            this.savePlants();
            this.render();
            
            // Reset form
            nameInput.value = '';
            intervalInput.value = '7';
            
            // Show success feedback
            this.showNotification(`Added "${name}" to your garden! 🌱`);
        }
    }

    waterPlant(plantId) {
        const plant = this.plants.find(p => p.id === plantId);
        if (plant) {
            plant.water();
            this.savePlants();
            this.render();
            this.showNotification(`Watered ${plant.name}! 💧`);
        }
    }

    deletePlant(plantId) {
        const plant = this.plants.find(p => p.id === plantId);
        if (plant) {
            if (confirm(`Are you sure you want to remove ${plant.name}?`)) {
                this.plants = this.plants.filter(p => p.id !== plantId);
                this.savePlants();
                this.render();
                this.showNotification(`Removed ${plant.name} from your garden`);
            }
        }
    }

    savePlants() {
        const plantsData = this.plants.map(plant => ({
            id: plant.id,
            name: plant.name,
            wateringInterval: plant.wateringInterval,
            lastWatered: plant.lastWatered.toISOString()
        }));
        localStorage.setItem('plants', JSON.stringify(plantsData));
    }

    loadPlants() {
        const stored = localStorage.getItem('plants');
        if (stored) {
            try {
                const plantsData = JSON.parse(stored);
                this.plants = plantsData.map(p => 
                    new Plant(p.name, p.wateringInterval, new Date(p.lastWatered))
                );
                // Preserve original IDs
                this.plants.forEach((plant, index) => {
                    plant.id = plantsData[index].id;
                });
            } catch (e) {
                console.error('Error loading plants:', e);
                this.plants = [];
            }
        }
    }

    render() {
        const plantsList = document.getElementById('plantsList');
        
        if (this.plants.length === 0) {
            plantsList.innerHTML = `
                <div class="empty-state" style="grid-column: 1 / -1;">
                    <div class="empty-state-emoji">🌵</div>
                    <p>No plants yet. Add one to get started!</p>
                </div>
            `;
            return;
        }

        plantsList.innerHTML = this.plants.map(plant => this.createPlantCard(plant)).join('');
    }

    createPlantCard(plant) {
        const needsWater = plant.needsWater();
        const cardClass = needsWater ? 'needs-water' : 'well-watered';
        const waterButtonText = needsWater ? '💧 Water Now' : '✓ Well Watered';
        
        return `
            <div class="plant-card ${cardClass}">
                <div class="plant-emoji">🌿</div>
                <div class="plant-name">${plant.name}</div>
                <div class="water-status">${plant.getWaterStatus()}</div>
                <div class="last-watered">Needs water every ${plant.wateringInterval} days</div>
                <div class="button-group">
                    <button class="water-btn" onclick="app.waterPlant(${plant.id})">
                        ${waterButtonText}
                    </button>
                    <button class="delete-btn" onclick="app.deletePlant(${plant.id})">
                        ✕
                    </button>
                </div>
            </div>
        `;
    }

    showNotification(message) {
        // Create notification element
        const notification = document.createElement('div');
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 15px 25px;
            border-radius: 8px;
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.2);
            font-weight: 600;
            z-index: 1000;
            animation: slideIn 0.3s ease-out;
        `;
        notification.textContent = message;
        
        document.body.appendChild(notification);
        
        // Add animation
        const style = document.createElement('style');
        style.textContent = `
            @keyframes slideIn {
                from {
                    transform: translateX(400px);
                    opacity: 0;
                }
                to {
                    transform: translateX(0);
                    opacity: 1;
                }
            }
            @keyframes slideOut {
                from {
                    transform: translateX(0);
                    opacity: 1;
                }
                to {
                    transform: translateX(400px);
                    opacity: 0;
                }
            }
        `;
        document.head.appendChild(style);
        
        // Remove notification after 3 seconds
        setTimeout(() => {
            notification.style.animation = 'slideOut 0.3s ease-out';
            setTimeout(() => {
                document.body.removeChild(notification);
            }, 300);
        }, 3000);
    }
}

// Initialize app when DOM is ready
let app;
document.addEventListener('DOMContentLoaded', () => {
    app = new PlantWateringApp();
});
