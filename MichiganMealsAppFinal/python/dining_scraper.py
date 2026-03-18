"""
Michigan Dining Hall Menu Scraper
==================================

This scraper extracts daily menu data from University of Michigan dining halls,
including meal periods, stations, food items, nutrition facts, and allergens.

The scraped data is saved to JSON files and can be inserted into a database
with linking to canonical food items for the rating system.

Author: Auto-generated for Michigan Meals App
Date: 2025-10-22
"""

import json
import logging
import os
import time
import tarfile

from datetime import datetime, date
from pathlib import Path
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict

from future.backports.datetime import timedelta
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import (
    TimeoutException,
    NoSuchElementException,
    StaleElementReferenceException,
    WebDriverException
)


# ============================================
# CONFIGURATION
# ============================================

DINING_HALLS = {
    "bursley": {
        "name": "Bursley",
        "url": "https://dining.umich.edu/menus-locations/dining-halls/bursley/"
    },
    "east-quad": {
        "name": "East Quad",
        "url": "https://dining.umich.edu/menus-locations/dining-halls/east-quad/"
    },
    "markley": {
        "name": "Markley",
        "url": "https://dining.umich.edu/menus-locations/dining-halls/markley/"
    },
    "mosher-jordan": {
        "name": "Mosher Jordan",
        "url": "https://dining.umich.edu/menus-locations/dining-halls/mosher-jordan/"
    },
    "north-quad": {
        "name": "North Quad",
        "url": "https://dining.umich.edu/menus-locations/dining-halls/north-quad/"
    },
    "south-quad": {
        "name": "South Quad",
        "url": "https://dining.umich.edu/menus-locations/dining-halls/south-quad/"
    },
    "twigs-at-oxford": {
        "name": "Twigs at Oxford",
        "url": "https://dining.umich.edu/menus-locations/dining-halls/twigs-at-oxford/"
    }
}

# CSS Selectors
SELECTORS = {
    "main_container": "#mdining-items",
    "meal_headers": "#mdining-items > h3 > a",
    "meal_courses_div": "div.courses",
    "station_containers": "ul.courses_wrapper > li",
    "station_name": "h4",
    "food_items": "ul.items > li",
    "food_name": "div.item-name",
    "food_link": "a",
    "nutrition_panel": "div.nutrition",
    "nutrition_table": "table.nutrition-facts tbody",
    "allergens_container": "div.allergens ul li",
}

# Timeouts
PAGE_LOAD_TIMEOUT = 30
ELEMENT_WAIT_TIMEOUT = 10
CLICK_DELAY = 0.5
ITEM_PROCESS_DELAY = 0.3

# Output directories
OUTPUT_DIR = Path(__file__).parent.parent / "scraped_data"
JSON_DIR = OUTPUT_DIR / "json"
TAR_DIR = OUTPUT_DIR / "tarball"
LOG_DIR = OUTPUT_DIR / "logs"


# ============================================
# DATA CLASSES
# ============================================

@dataclass
class NutritionFacts:
    """Nutrition information for a food item"""
    serving_size: Optional[str] = None
    calories: Optional[int] = None
    total_fat: Optional[str] = None
    saturated_fat: Optional[str] = None
    trans_fat: Optional[str] = None
    cholesterol: Optional[str] = None
    sodium: Optional[str] = None
    total_carbohydrate: Optional[str] = None
    dietary_fiber: Optional[str] = None
    sugars: Optional[str] = None
    protein: Optional[str] = None
    vitamin_a: Optional[str] = None
    vitamin_c: Optional[str] = None
    calcium: Optional[str] = None
    iron: Optional[str] = None


@dataclass
class FoodItem:
    """Individual food item with nutrition and allergens"""
    item_name: str
    allergens: List[str]
    nutrition: Optional[NutritionFacts] = None


@dataclass
class Station:
    """Food station within a meal period"""
    station_name: str
    items: List[FoodItem]


@dataclass
class MealPeriod:
    """Meal period (breakfast, lunch, dinner, brunch)"""
    meal_period: str  # normalized lowercase
    meal_period_display: str  # original display text
    stations: List[Station]


@dataclass
class ScrapedMenu:
    """Complete menu data for a dining hall"""
    scrape_metadata: Dict[str, Any]
    meals: List[MealPeriod]


# ============================================
# LOGGING SETUP
# ============================================

def setup_logging(dining_hall_id: str) -> logging.Logger:
    """Setup logging for the scraper"""
    LOG_DIR.mkdir(parents=True, exist_ok=True)

    log_file = LOG_DIR / f"scrape_{date.today().isoformat()}_{dining_hall_id}.log"

    logger = logging.getLogger(f"dining_scraper_{dining_hall_id}")
    logger.setLevel(logging.DEBUG)

    # File handler
    fh = logging.FileHandler(log_file)
    fh.setLevel(logging.DEBUG)

    # Console handler
    ch = logging.StreamHandler()
    ch.setLevel(logging.INFO)

    # Formatter
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    fh.setFormatter(formatter)
    ch.setFormatter(formatter)

    logger.addHandler(fh)
    logger.addHandler(ch)

    return logger


# ============================================
# SELENIUM DRIVER SETUP
# ============================================

def create_driver(headless: bool = True, chromedriver_path: Optional[str] = None) -> webdriver.Chrome:
    """Create and configure Chrome WebDriver"""
    chrome_options = Options()

    if headless:
        chrome_options.add_argument('--headless')

    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-dev-shm-usage')
    chrome_options.add_argument('--disable-gpu')
    chrome_options.add_argument('--window-size=1920,1080')
    chrome_options.add_argument('--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36')

    if chromedriver_path:
        service = Service(executable_path=chromedriver_path)
        driver = webdriver.Chrome(service=service, options=chrome_options)
    else:
        driver = webdriver.Chrome(options=chrome_options)

    driver.set_page_load_timeout(PAGE_LOAD_TIMEOUT)

    return driver


# ============================================
# SCRAPING FUNCTIONS
# ============================================

class DiningHallScraper:
    """Scraper for a single dining hall"""

    def __init__(self, driver: webdriver.Chrome, logger: logging.Logger):
        self.driver = driver
        self.logger = logger
        self.wait = WebDriverWait(driver, ELEMENT_WAIT_TIMEOUT)

    def safe_click(self, element) -> bool:
        """Safely click an element with fallback to JavaScript"""
        try:
            element.click()
            return True
        except Exception as e:
            self.logger.debug(f"Normal click failed, trying JavaScript click: {e}")
            try:
                self.driver.execute_script("arguments[0].click();", element)
                return True
            except Exception as e2:
                self.logger.error(f"JavaScript click also failed: {e2}")
                return False

    def extract_nutrition_facts(self, nutrition_table) -> Optional[NutritionFacts]:
        """Extract nutrition facts from the nutrition table"""
        try:
            nutrition = NutritionFacts()
            rows = nutrition_table.find_elements(By.TAG_NAME, "tr")

            for row in rows:
                try:
                    row_class = row.get_attribute("class") or ""
                    cells = row.find_elements(By.TAG_NAME, "td")

                    if not cells:
                        continue

                    cell_text = cells[0].text.strip()

                    # Serving size
                    if "serving-size" in row_class:
                        parts = cell_text.split("Serving Size")
                        if len(parts) > 1:
                            nutrition.serving_size = parts[1].strip()

                    # Calories
                    elif "portion-calories" in row_class:
                        parts = cell_text.split("Calories")
                        if len(parts) > 1:
                            try:
                                nutrition.calories = int(parts[1].strip())
                            except ValueError:
                                nutrition.calories = None

                    # Parse nutrient rows
                    elif "Total Fat" in cell_text:
                        nutrition.total_fat = cell_text.replace("Total Fat", "").strip()
                    elif "Saturated Fat" in cell_text:
                        nutrition.saturated_fat = cell_text.replace("Saturated Fat", "").strip()
                    elif "Trans Fat" in cell_text:
                        nutrition.trans_fat = cell_text.replace("Trans Fat", "").strip()
                    elif "Cholesterol" in cell_text:
                        nutrition.cholesterol = cell_text.replace("Cholesterol", "").strip()
                    elif "Sodium" in cell_text:
                        nutrition.sodium = cell_text.replace("Sodium", "").strip()
                    elif "Total Carbohydrate" in cell_text:
                        nutrition.total_carbohydrate = cell_text.replace("Total Carbohydrate", "").strip()
                    elif "Dietary Fiber" in cell_text:
                        nutrition.dietary_fiber = cell_text.replace("Dietary Fiber", "").strip()
                    elif "Sugars" in cell_text:
                        nutrition.sugars = cell_text.replace("Sugars", "").strip()
                    elif "Protein" in cell_text:
                        nutrition.protein = cell_text.replace("Protein", "").strip()
                    elif "Vitamin A" in cell_text:
                        if len(cells) > 1:
                            nutrition.vitamin_a = cells[1].text.strip()
                    elif "Vitamin C" in cell_text:
                        if len(cells) > 1:
                            nutrition.vitamin_c = cells[1].text.strip()
                    elif "Calcium" in cell_text:
                        if len(cells) > 1:
                            nutrition.calcium = cells[1].text.strip()
                    elif "Iron" in cell_text:
                        if len(cells) > 1:
                            nutrition.iron = cells[1].text.strip()

                except Exception as e:
                    self.logger.debug(f"Error parsing nutrition row: {e}")
                    continue

            return nutrition

        except Exception as e:
            self.logger.error(f"Error extracting nutrition facts: {e}")
            return None

    def extract_allergens(self, item_element) -> List[str]:
        """Extract allergen information from food item"""
        try:
            allergen_elements = item_element.find_elements(
                By.CSS_SELECTOR,
                SELECTORS["allergens_container"]
            )
            allergens = [elem.text.strip().lower() for elem in allergen_elements if elem.text.strip()]
            return allergens
        except NoSuchElementException:
            return []
        except Exception as e:
            self.logger.debug(f"Error extracting allergens: {e}")
            return []

    def scrape_food_item(self, item_element, station_name: str, item_index: int) -> Optional[FoodItem]:
        """Scrape a single food item"""
        try:
            # Get food name
            name_element = item_element.find_element(By.CSS_SELECTOR, SELECTORS["food_name"])
            item_name = name_element.text.strip()

            if not item_name:
                self.logger.debug(f"Empty item name in station {station_name}, skipping")
                return None

            self.logger.debug(f"  Processing item: {item_name}")

            # Click to expand nutrition
            link_element = item_element.find_element(By.CSS_SELECTOR, SELECTORS["food_link"])

            if not self.safe_click(link_element):
                self.logger.warning(f"Could not click item: {item_name}")
                return FoodItem(item_name=item_name, allergens=[])

            time.sleep(CLICK_DELAY)

            # Wait for nutrition panel to appear
            try:
                nutrition_panel = self.wait.until(
                    EC.visibility_of(
                        item_element.find_element(By.CSS_SELECTOR, SELECTORS["nutrition_panel"])
                    )
                )
            except TimeoutException:
                self.logger.warning(f"Nutrition panel did not appear for: {item_name}")
                return FoodItem(item_name=item_name, allergens=[])

            # Extract allergens
            allergens = self.extract_allergens(item_element)

            # Extract nutrition facts
            nutrition_facts = None
            try:
                nutrition_table = nutrition_panel.find_element(
                    By.CSS_SELECTOR,
                    SELECTORS["nutrition_table"]
                )
                nutrition_facts = self.extract_nutrition_facts(nutrition_table)
            except NoSuchElementException:
                self.logger.warning(f"No nutrition table found for: {item_name}")

            # Close nutrition panel by clicking again
            self.safe_click(link_element)
            time.sleep(ITEM_PROCESS_DELAY)

            return FoodItem(
                item_name=item_name,
                allergens=allergens,
                nutrition=nutrition_facts
            )

        except StaleElementReferenceException:
            self.logger.warning(f"Stale element in station {station_name}, item {item_index}")
            return None
        except Exception as e:
            self.logger.error(f"Error scraping food item in station {station_name}: {e}")
            return None

    def scrape_station(self, station_element, meal_period: str) -> Optional[Station]:
        """Scrape a single station within a meal period"""
        try:
            # Get station name
            station_name_element = station_element.find_element(By.CSS_SELECTOR, SELECTORS["station_name"])
            station_name = station_name_element.text.strip()

            if not station_name:
                self.logger.debug("Empty station name, skipping")
                return None

            self.logger.info(f" Scraping station: {station_name}")

            # Find all food items in this station
            food_item_elements = station_element.find_elements(
                By.CSS_SELECTOR,
                SELECTORS["food_items"]
            )

            if not food_item_elements:
                self.logger.info(f"  No food items found in station: {station_name}")
                return Station(station_name=station_name, items=[])

            self.logger.info(f"  Found {len(food_item_elements)} items in station")

            # Scrape each food item
            items = []
            for idx, item_element in enumerate(food_item_elements):
                try:
                    food_item = self.scrape_food_item(item_element, station_name, idx)
                    if food_item:
                        items.append(food_item)
                except Exception as e:
                    self.logger.error(f"Error processing item {idx} in station {station_name}: {e}")
                    continue

            self.logger.info(f"  Successfully scraped {len(items)} items from station: {station_name}")

            return Station(station_name=station_name, items=items)

        except NoSuchElementException as e:
            self.logger.warning(f"Station element not found: {e}")
            return None
        except Exception as e:
            self.logger.error(f"Error scraping station: {e}")
            return None

    def scrape_meal_period(self, meal_header_element, index: int) -> Optional[MealPeriod]:
        """Scrape a single meal period (breakfast, lunch, dinner, brunch)"""
        try:
            # Get meal period name
            meal_display_name = meal_header_element.text.strip()
            meal_normalized = meal_display_name.lower().replace(" ", "_")

            self.logger.info(f"Scraping meal period: {meal_display_name}")

            # Click to expand meal period
            if not self.safe_click(meal_header_element):
                self.logger.error(f"Could not expand meal period: {meal_display_name}")
                return None

            time.sleep(CLICK_DELAY)

            # Wait for courses div to become visible
            try:
                # Find the courses div that's a sibling of the h3 parent
                courses_div = self.wait.until(
                    EC.visibility_of_element_located(
                        (By.CSS_SELECTOR, f"#mdining-items > {SELECTORS['meal_courses_div']}:nth-of-type({(index) + 2})")
                    )
                )
            except TimeoutException:
                self.logger.error(f"Courses div did not appear for: {meal_display_name}")
                return None

            # Find all stations in this meal period
            station_elements = courses_div.find_elements(
                By.CSS_SELECTOR,
                SELECTORS["station_containers"]
            )

            if not station_elements:
                self.logger.warning(f"No stations found for meal period: {meal_display_name}")
                return MealPeriod(
                    meal_period=meal_normalized,
                    meal_period_display=meal_display_name,
                    stations=[]
                )

            self.logger.info(f"Found {len(station_elements)} stations in meal period")

            # Scrape each station
            stations = []
            for station_element in station_elements:
                try:
                    station = self.scrape_station(station_element, meal_display_name)
                    if station:
                        stations.append(station)
                except Exception as e:
                    self.logger.error(f"Error processing station in {meal_display_name}: {e}")
                    continue

            self.logger.info(f"Successfully scraped {len(stations)} stations from: {meal_display_name}")

            return MealPeriod(
                meal_period=meal_normalized,
                meal_period_display=meal_display_name,
                stations=stations
            )

        except Exception as e:
            self.logger.error(f"Error scraping meal period: {e}")
            return None

    def scrape_dining_hall(self, dining_hall_id: str, url: str, dining_hall_name: str) -> Optional[ScrapedMenu]:
        """Scrape complete menu for a dining hall"""
        try:
            self.logger.info(f"Navigating to {dining_hall_name}: {url}")
            self.driver.get(url)

            # Wait for main container to load
            try:
                self.wait.until(
                    EC.presence_of_element_located((By.CSS_SELECTOR, SELECTORS["main_container"]))
                )
            except TimeoutException:
                self.logger.error(f"Main container did not load for {dining_hall_name}")
                return None

            time.sleep(1)  # Extra wait for dynamic content

            # Find all meal period headers
            meal_headers = self.driver.find_elements(By.CSS_SELECTOR, SELECTORS["meal_headers"])

            if not meal_headers:
                self.logger.warning(f"No meal periods found for {dining_hall_name}")
                return None

            self.logger.info(f"Found {len(meal_headers)} meal periods")

            # Scrape each meal period
            meals = []
            for idx, meal_header in enumerate(meal_headers):
                try:
                    # Re-find element to avoid stale reference
                    fresh_headers = self.driver.find_elements(By.CSS_SELECTOR, SELECTORS["meal_headers"])
                    if idx >= len(fresh_headers):
                        break

                    meal_period = self.scrape_meal_period(fresh_headers[idx], idx)
                    if meal_period:
                        meals.append(meal_period)
                except Exception as e:
                    self.logger.error(f"Error processing meal period {idx}: {e}")
                    continue

            # Create metadata
            scrape_metadata = {
                "scrape_timestamp": datetime.now().isoformat(),
                "scrape_date": date.today().isoformat(),
                "version": "1.0",
                "dining_hall_id": dining_hall_id,
                "dining_hall_name": dining_hall_name
            }

            scraped_menu = ScrapedMenu(
                scrape_metadata=scrape_metadata,
                meals=meals
            )

            self.logger.info(f"Successfully scraped {len(meals)} meal periods from {dining_hall_name}")

            return scraped_menu

        except Exception as e:
            self.logger.error(f"Fatal error scraping {dining_hall_name}: {e}")
            return None


# ============================================
# JSON EXPORT
# ============================================

def save_to_json(scraped_menu: ScrapedMenu, dining_hall_id: str) -> Path:
    """Save scraped menu to JSON file"""
    # Create directory structure
    today = date.today().isoformat()
    date_dir = JSON_DIR / today
    date_dir.mkdir(parents=True, exist_ok=True)

    # Create filename
    json_file = date_dir / f"{dining_hall_id}.json"

    # Convert dataclasses to dict
    def convert_to_dict(obj):
        if hasattr(obj, '__dict__'):
            return {k: convert_to_dict(v) for k, v in obj.__dict__.items()}
        elif isinstance(obj, list):
            return [convert_to_dict(item) for item in obj]
        elif isinstance(obj, dict):
            return {k: convert_to_dict(v) for k, v in obj.items()}
        else:
            return obj

    menu_dict = convert_to_dict(scraped_menu)

    # Write to file
    with open(json_file, 'w', encoding='utf-8') as f:
        json.dump(menu_dict, f, indent=2, ensure_ascii=False)

    return json_file


# ============================================
# MAIN EXECUTION
# ============================================

def scrape_all_dining_halls(
    chromedriver_path: Optional[str] = None,
    headless: bool = True,
    dining_halls: Optional[List[str]] = None
) -> Dict[str, Optional[Path]]:
    """
    Scrape all dining halls and save to JSON

    Args:
        chromedriver_path: Path to chromedriver executable (optional)
        headless: Run browser in headless mode
        dining_halls: List of dining hall IDs to scrape (default: all)

    Returns:
        Dict mapping dining_hall_id to JSON file path (or None if failed)
    """
    results = {}

    # Determine which halls to scrape
    halls_to_scrape = dining_halls if dining_halls else list(DINING_HALLS.keys())

    # Create driver
    try:
        driver = create_driver(headless=headless, chromedriver_path=chromedriver_path)
    except Exception as e:
        print(f"Failed to create WebDriver: {e}")
        return results

    try:
        for dining_hall_id in halls_to_scrape:
            if dining_hall_id not in DINING_HALLS:
                print(f"Unknown dining hall: {dining_hall_id}")
                continue

            hall_info = DINING_HALLS[dining_hall_id]
            logger = setup_logging(dining_hall_id)

            logger.info(f"=" * 80)
            logger.info(f"Starting scrape for {hall_info['name']}")
            logger.info(f"=" * 80)

            try:
                scraper = DiningHallScraper(driver, logger)
                scraped_menu = scraper.scrape_dining_hall(
                    dining_hall_id,
                    hall_info['url'],
                    hall_info['name']
                )

                if scraped_menu:
                    json_path = save_to_json(scraped_menu, dining_hall_id)
                    logger.info(f"Saved menu to: {json_path}")
                    results[dining_hall_id] = json_path
                else:
                    logger.error(f"Failed to scrape {hall_info['name']}")
                    results[dining_hall_id] = None

            except Exception as e:
                logger.error(f"Exception while scraping {hall_info['name']}: {e}")
                results[dining_hall_id] = None

            # Small delay between dining halls
            time.sleep(2)

    finally:
        driver.quit()

    return results


if __name__ == "__main__":
    import sys

    # Configuration
    CHROMEDRIVER_PATH = "/Users/alex/Downloads/chromedriver-mac-arm64-2/chromedriver"
    HEADLESS = True  # Set to False for debugging

    # Optional: specify which halls to scrape
    # HALLS = ["bursley", "south-quad"]  # or None for all
    HALLS = None

    SHOULD_TAR = True
    input_tar = f"{JSON_DIR}/{(date.today() - timedelta(days=1)).isoformat()}"
    output_tar = f"{TAR_DIR}/{(date.today() - timedelta(days=1)).isoformat()}.tar.gz"

    if(SHOULD_TAR):
        print("Archiving past data.")
        if os.path.exists(input_tar):
            try:
                tarfile.open(output_tar, "w:gz").add(input_tar)
                print("Successfully archived past data.")
                try:
                    os.remove(input_tar)
                    print("Successfully removed past data.")
                except Exception as e:
                    print(f"\033[31mFailed to remove {input_tar}: {e}\033[0m")
            except Exception as e:
                print(f"\033[31mFailed to create tar file: {e}\033[0m")
        else:
            print("No old files to archive.")

    print("Michigan Dining Hall Scraper")
    print("=" * 80)
    print(f"Scraping date: {date.today().isoformat()}")
    print(f"Headless mode: {HEADLESS}")
    print(f"Output directory: {JSON_DIR}")
    print("=" * 80)

    results = scrape_all_dining_halls(
        chromedriver_path=CHROMEDRIVER_PATH,
        headless=HEADLESS,
        dining_halls=HALLS
    )

    print("\n" + "=" * 80)
    print("SCRAPING RESULTS")
    print("=" * 80)

    success_count = sum(1 for path in results.values() if path is not None)

    for hall_id, json_path in results.items():
        status = "✓ SUCCESS" if json_path else "✗ FAILED"
        print(f"{status}: {DINING_HALLS[hall_id]['name']}")
        if json_path:
            print(f"  → {json_path}")

    print("=" * 80)
    print(f"Successfully scraped: {success_count}/{len(results)} dining halls")
    print("=" * 80)

    sys.exit(0 if success_count == len(results) else 1)
