DEFAULT_TREATMENT_PACKAGES: dict[str, dict[str, object]] = {
    "normal": {
        "name": "Daily Glow Maintenance",
        "steps": ["gentle cleanser", "light moisturizer", "broad-spectrum sunscreen"],
        "follow_up_days": 30,
    },
    "oily": {
        "name": "Oil Balance Care",
        "steps": ["gel cleanser", "niacinamide serum", "oil-free moisturizer", "sunscreen"],
        "follow_up_days": 14,
    },
    "dry": {
        "name": "Barrier Repair Care",
        "steps": ["cream cleanser", "hydrating serum", "barrier moisturizer", "sunscreen"],
        "follow_up_days": 14,
    },
    "combination": {
        "name": "Combination Balance Care",
        "steps": ["gentle cleanser", "zone-based serum", "light moisturizer", "sunscreen"],
        "follow_up_days": 21,
    },
    "sensitive": {
        "name": "Sensitive Skin Calm Care",
        "steps": ["low-irritation cleanser", "calming serum", "barrier cream", "mineral sunscreen"],
        "follow_up_days": 10,
    },
    "acne": {
        "name": "Acne Control Plan",
        "steps": ["gentle cleanser", "spot treatment", "non-comedogenic moisturizer", "sunscreen"],
        "follow_up_days": 14,
    },
    "dark_spots": {
        "name": "Dark Spot Brightening Plan",
        "steps": ["gentle cleanser", "brightening serum", "moisturizer", "strict sunscreen"],
        "follow_up_days": 30,
    },
    "oiliness": {
        "name": "Shine Control Plan",
        "steps": ["gel cleanser", "oil-control serum", "light moisturizer", "sunscreen"],
        "follow_up_days": 14,
    },
    "dryness": {
        "name": "Hydration Recovery Plan",
        "steps": ["cream cleanser", "hydrating toner", "barrier moisturizer", "sunscreen"],
        "follow_up_days": 14,
    },
}
