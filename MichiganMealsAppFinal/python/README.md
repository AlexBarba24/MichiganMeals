# Michigan Dining Hall Scraper

Production-ready web scraper for University of Michigan dining hall menus.

## Features

✅ **Complete Menu Extraction**
- All 7 dining halls supported
- Dynamic meal periods (breakfast, lunch, dinner, brunch)
- Stations and food items with full hierarchy
- Complete nutrition facts (calories, macros, vitamins, minerals)
- Allergen information

✅ **Rating System Integration**
- Links scraped items to canonical food items for persistent ratings
- Tracks when items are last seen on menus
- Enables community and user-specific ratings

✅ **Robust & Production-Ready**
- Comprehensive error handling and retries
- Detailed logging (console + file)
- Configurable headless/debug modes
- JSON export with organized directory structure
- Database insertion (SQLite & PostgreSQL support)

## Installation

### 1. Install Python Dependencies

```bash
cd python
pip install -r requirements.txt
```

### 2. Install ChromeDriver

**macOS:**
```bash
brew install chromedriver
```

**Manual Download:**
- Download from: https://chromedriver.chromium.org/
- Ensure version matches your Chrome browser
- Update path in script: `CHROMEDRIVER_PATH`

## Usage

### Basic Scraping (JSON Only)

```bash
python dining_scraper.py
```

This will:
- Scrape all 7 dining halls
- Save JSON files to: `scraped_data/json/YYYY-MM-DD/`
- Create logs in: `scraped_data/logs/`

### Scraping with Database Insertion

```python
from dining_scraper import scrape_all_dining_halls
from database import DatabaseManager

# Scrape menus
results = scrape_all_dining_halls(
    chromedriver_path="/path/to/chromedriver",
    headless=True
)

# Insert into database
with DatabaseManager(db_type="sqlite") as db:
    for hall_id, json_path in results.items():
        if json_path:
            # Load from JSON and insert
            import json
            with open(json_path) as f:
                menu_data = json.load(f)
            # Convert back to ScrapedMenu object and insert
            # db.insert_scraped_menu(scraped_menu)
```

### Configuration

Edit `dining_scraper.py` main block:

```python
# Path to ChromeDriver
CHROMEDRIVER_PATH = "/path/to/chromedriver"

# Run headless (True) or visible browser for debugging (False)
HEADLESS = True

# Scrape specific halls or None for all
HALLS = ["bursley", "south-quad"]  # or None
```

## Output Structure

```
scraped_data/
├── json/
│   └── 2025-10-22/
│       ├── bursley.json
│       ├── east-quad.json
│       ├── markley.json
│       ├── mosher-jordan.json
│       ├── north-quad.json
│       ├── south-quad.json
│       └── twigs-at-oxford.json
├── logs/
│   ├── scrape_2025-10-22_bursley.log
│   ├── scrape_2025-10-22_east-quad.log
│   └── ...
└── database/
    └── dining.db  (SQLite database)
```

## JSON Output Format

```json
{
  "scrape_metadata": {
    "scrape_timestamp": "2025-10-22T14:30:00",
    "scrape_date": "2025-10-22",
    "version": "1.0",
    "dining_hall_id": "bursley",
    "dining_hall_name": "Bursley"
  },
  "meals": [
    {
      "meal_period": "breakfast",
      "meal_period_display": "Breakfast",
      "stations": [
        {
          "station_name": "Hot Cereal",
          "items": [
            {
              "item_name": "Oatmeal",
              "allergens": ["oats"],
              "nutrition": {
                "serving_size": "8 oz Cup (227g)",
                "calories": 164,
                "total_fat": "3g",
                "saturated_fat": "1g",
                "trans_fat": "0g",
                "cholesterol": "0mg",
                "sodium": "3mg",
                "total_carbohydrate": "29g",
                "dietary_fiber": "4g",
                "sugars": "0g",
                "protein": "6g",
                "vitamin_a": "0%",
                "vitamin_c": "0%",
                "calcium": "2%",
                "iron": "10%"
              }
            }
          ]
        }
      ]
    }
  ]
}
```

## Database Schema

The scraper populates a relational database with:

**Menu Data Tables:**
- `dining_halls` - Dining hall reference data
- `scrape_runs` - Track each scrape execution
- `meal_periods` - Breakfast, lunch, dinner, brunch
- `stations` - Food stations within meals
- `food_items` - Individual food items
- `nutrition_facts` - Complete nutrition information
- `allergens` - Allergen master list
- `food_item_allergens` - Many-to-many allergen relationships

**Rating System Tables:**
- `canonical_food_items` - Persistent food items for ratings
- `users` - User accounts
- `user_ratings` - Individual ratings (1-5 stars)
- `user_preferences` - Dietary restrictions and preferences

### Canonical Food Item Linking

The scraper automatically links each scraped food item to a canonical record:
- **Match Key**: `dining_hall + meal_period + station + item_name`
- **New Items**: Creates new canonical record
- **Existing Items**: Links to existing record, updates `last_seen` date
- **Purpose**: Ratings persist even when menus change daily

## Scheduling (Cron Job)

To run daily at 6 AM:

```bash
crontab -e
```

Add:
```
0 6 * * * cd /path/to/python && /usr/bin/python3 dining_scraper.py >> /path/to/logs/cron.log 2>&1
```

## Debugging

### Run in Visible Browser Mode

Set `HEADLESS = False` in the script to watch the scraper work.

### Check Logs

Detailed logs are saved to `scraped_data/logs/` with separate files per dining hall.

### Test Single Dining Hall

```python
results = scrape_all_dining_halls(
    chromedriver_path="/path/to/chromedriver",
    headless=False,
    dining_halls=["bursley"]  # Test just one hall
)
```

## Troubleshooting

**ChromeDriver version mismatch:**
- Ensure ChromeDriver version matches your Chrome browser version
- Download correct version from: https://chromedriver.chromium.org/

**Elements not found:**
- Website HTML structure may have changed
- Check logs for specific CSS selectors failing
- Update selectors in `SELECTORS` dict

**Timeout errors:**
- Increase `ELEMENT_WAIT_TIMEOUT` constant
- Check internet connection
- Verify website is accessible

**Database errors:**
- Check file permissions for SQLite database
- Verify PostgreSQL connection parameters
- Check logs for specific SQL errors

## Performance

- **Average scrape time**: 2-3 minutes per dining hall
- **Total time (all 7 halls)**: ~15-20 minutes
- **JSON file size**: ~50-200 KB per dining hall
- **Database size**: ~1-2 MB per day

## Future Enhancements

- [ ] Multi-date scraping (scrape upcoming week)
- [ ] Parallel scraping (multiple halls simultaneously)
- [ ] Incremental updates (detect changes since last scrape)
- [ ] Image downloading (food item photos)
- [ ] Email notifications on scrape failure
- [ ] Web dashboard for scrape monitoring

## License

Part of Michigan Meals App - Internal use for University of Michigan students
