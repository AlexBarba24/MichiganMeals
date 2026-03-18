"""
Database Module for Michigan Dining Scraper
============================================

Handles database operations including:
- Schema creation
- Inserting scraped menu data
- Linking to canonical food items for rating system
- Managing user ratings

Supports both SQLite (for development) and PostgreSQL (for production)

Author: Auto-generated for Michigan Meals App
Date: 2025-10-22
"""

import logging
from datetime import date, datetime
from typing import Optional, List, Dict, Any
from pathlib import Path

try:
    import psycopg2
    from psycopg2 import sql
    from psycopg2.extras import execute_values
    POSTGRES_AVAILABLE = True
except ImportError:
    POSTGRES_AVAILABLE = False
    print("Warning: psycopg2 not installed. PostgreSQL support disabled.")

import sqlite3


# ============================================
# DATABASE SCHEMAS
# ============================================

SQLITE_SCHEMA = """
-- Dining Halls
CREATE TABLE IF NOT EXISTS dining_halls (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    url TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Scrape Runs
CREATE TABLE IF NOT EXISTS scrape_runs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    dining_hall_id TEXT REFERENCES dining_halls(id),
    menu_date DATE NOT NULL,
    scrape_timestamp TIMESTAMP NOT NULL,
    status TEXT NOT NULL,
    items_scraped INTEGER DEFAULT 0,
    error_message TEXT,
    UNIQUE(dining_hall_id, menu_date)
);

-- Meal Periods
CREATE TABLE IF NOT EXISTS meal_periods (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    scrape_run_id INTEGER REFERENCES scrape_runs(id) ON DELETE CASCADE,
    meal_period TEXT NOT NULL,
    meal_period_display TEXT NOT NULL
);

-- Stations
CREATE TABLE IF NOT EXISTS stations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    meal_period_id INTEGER REFERENCES meal_periods(id) ON DELETE CASCADE,
    station_name TEXT NOT NULL,
    display_order INTEGER DEFAULT 0
);

-- Food Items
CREATE TABLE IF NOT EXISTS food_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    station_id INTEGER REFERENCES stations(id) ON DELETE CASCADE,
    item_name TEXT NOT NULL,
    display_order INTEGER DEFAULT 0,
    canonical_food_id INTEGER REFERENCES canonical_food_items(id)
);

-- Nutrition Facts
CREATE TABLE IF NOT EXISTS nutrition_facts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    food_item_id INTEGER REFERENCES food_items(id) ON DELETE CASCADE,
    serving_size TEXT,
    calories INTEGER,
    total_fat TEXT,
    saturated_fat TEXT,
    trans_fat TEXT,
    cholesterol TEXT,
    sodium TEXT,
    total_carbohydrate TEXT,
    dietary_fiber TEXT,
    sugars TEXT,
    protein TEXT,
    vitamin_a TEXT,
    vitamin_c TEXT,
    calcium TEXT,
    iron TEXT
);

-- Allergens
CREATE TABLE IF NOT EXISTS allergens (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    allergen_name TEXT UNIQUE NOT NULL
);

-- Food Item Allergens
CREATE TABLE IF NOT EXISTS food_item_allergens (
    food_item_id INTEGER REFERENCES food_items(id) ON DELETE CASCADE,
    allergen_id INTEGER REFERENCES allergens(id),
    PRIMARY KEY (food_item_id, allergen_id)
);

-- Canonical Food Items (for ratings)
CREATE TABLE IF NOT EXISTS canonical_food_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    dining_hall_id TEXT REFERENCES dining_halls(id),
    meal_period TEXT NOT NULL,
    station_name TEXT NOT NULL,
    item_name TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen DATE,
    average_rating REAL DEFAULT 0.0,
    total_ratings INTEGER DEFAULT 0,
    UNIQUE(dining_hall_id, meal_period, station_name, item_name)
);

-- Users
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    auth_token_hash TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- User Ratings
CREATE TABLE IF NOT EXISTS user_ratings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    canonical_food_id INTEGER REFERENCES canonical_food_items(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, canonical_food_id)
);

-- User Preferences
CREATE TABLE IF NOT EXISTS user_preferences (
    user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    dietary_restrictions TEXT,
    allergens TEXT,
    favorite_stations TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_scrape_runs_date ON scrape_runs(menu_date);
CREATE INDEX IF NOT EXISTS idx_scrape_runs_dining_hall ON scrape_runs(dining_hall_id);
CREATE INDEX IF NOT EXISTS idx_food_items_name ON food_items(item_name);
CREATE INDEX IF NOT EXISTS idx_food_items_canonical ON food_items(canonical_food_id);
CREATE INDEX IF NOT EXISTS idx_canonical_food_items_lookup ON canonical_food_items(dining_hall_id, meal_period, station_name, item_name);
CREATE INDEX IF NOT EXISTS idx_canonical_food_items_rating ON canonical_food_items(average_rating DESC, total_ratings DESC);
CREATE INDEX IF NOT EXISTS idx_canonical_food_items_last_seen ON canonical_food_items(last_seen);
CREATE INDEX IF NOT EXISTS idx_user_ratings_user ON user_ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_user_ratings_food ON user_ratings(canonical_food_id);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
"""


# ============================================
# DATABASE MANAGER
# ============================================

class DatabaseManager:
    """Manages database connections and operations"""

    def __init__(self, db_type: str = "sqlite", db_path: Optional[str] = None, **pg_params):
        """
        Initialize database manager

        Args:
            db_type: "sqlite" or "postgres"
            db_path: Path to SQLite database file (for SQLite)
            **pg_params: PostgreSQL connection parameters (host, database, user, password)
        """
        self.db_type = db_type
        self.logger = logging.getLogger("database_manager")

        if db_type == "sqlite":
            if not db_path:
                # Default to scraped_data/database directory
                db_path = Path(__file__).parent.parent / "scraped_data" / "database" / "dining.db"
                db_path.parent.mkdir(parents=True, exist_ok=True)

            self.db_path = db_path
            self.conn = sqlite3.connect(db_path)
            self.conn.row_factory = sqlite3.Row
            self.logger.info(f"Connected to SQLite database: {db_path}")
            self._init_sqlite_schema()

        elif db_type == "postgres":
            if not POSTGRES_AVAILABLE:
                raise ImportError("psycopg2 not installed. Cannot use PostgreSQL.")

            self.conn = psycopg2.connect(**pg_params)
            self.logger.info("Connected to PostgreSQL database")
            # PostgreSQL schema initialization would go here
            # For now, assume schema is already created

        else:
            raise ValueError(f"Unsupported database type: {db_type}")

    def _init_sqlite_schema(self):
        """Initialize SQLite database schema"""
        cursor = self.conn.cursor()
        cursor.executescript(SQLITE_SCHEMA)
        self.conn.commit()
        self.logger.info("SQLite schema initialized")

    def close(self):
        """Close database connection"""
        if self.conn:
            self.conn.close()
            self.logger.info("Database connection closed")

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()

    # ============================================
    # CANONICAL FOOD ITEM MANAGEMENT
    # ============================================

    def get_or_create_canonical_food_item(
        self,
        dining_hall_id: str,
        meal_period: str,
        station_name: str,
        item_name: str,
        current_date: date
    ) -> int:
        """
        Get existing canonical food item ID or create a new one

        This is the key function that links scraped items to persistent rating records

        Args:
            dining_hall_id: Dining hall identifier
            meal_period: Normalized meal period (breakfast, lunch, dinner, brunch)
            station_name: Station name
            item_name: Food item name
            current_date: Date this item was seen

        Returns:
            canonical_food_id: ID of the canonical food item
        """
        cursor = self.conn.cursor()

        try:
            if self.db_type == "sqlite":
                # Check if canonical item exists
                cursor.execute("""
                    SELECT id FROM canonical_food_items
                    WHERE dining_hall_id = ? AND meal_period = ?
                    AND station_name = ? AND item_name = ?
                """, (dining_hall_id, meal_period, station_name, item_name))

                result = cursor.fetchone()

                if result:
                    # Update last_seen date
                    canonical_id = result[0] if isinstance(result, tuple) else result['id']
                    cursor.execute("""
                        UPDATE canonical_food_items
                        SET last_seen = ?
                        WHERE id = ?
                    """, (current_date, canonical_id))
                    self.conn.commit()
                    return canonical_id
                else:
                    # Create new canonical item
                    cursor.execute("""
                        INSERT INTO canonical_food_items
                        (dining_hall_id, meal_period, station_name, item_name, last_seen)
                        VALUES (?, ?, ?, ?, ?)
                    """, (dining_hall_id, meal_period, station_name, item_name, current_date))
                    self.conn.commit()
                    return cursor.lastrowid

            elif self.db_type == "postgres":
                # PostgreSQL version with UPSERT
                cursor.execute("""
                    INSERT INTO canonical_food_items
                    (dining_hall_id, meal_period, station_name, item_name, last_seen)
                    VALUES (%s, %s, %s, %s, %s)
                    ON CONFLICT (dining_hall_id, meal_period, station_name, item_name)
                    DO UPDATE SET last_seen = EXCLUDED.last_seen
                    RETURNING id
                """, (dining_hall_id, meal_period, station_name, item_name, current_date))
                self.conn.commit()
                return cursor.fetchone()[0]

        except Exception as e:
            self.logger.error(f"Error getting/creating canonical food item: {e}")
            self.conn.rollback()
            raise

    # ============================================
    # DINING HALL MANAGEMENT
    # ============================================

    def ensure_dining_hall_exists(self, dining_hall_id: str, name: str, url: str):
        """Ensure dining hall record exists in database"""
        cursor = self.conn.cursor()

        try:
            if self.db_type == "sqlite":
                cursor.execute("""
                    INSERT OR IGNORE INTO dining_halls (id, name, url)
                    VALUES (?, ?, ?)
                """, (dining_hall_id, name, url))
            elif self.db_type == "postgres":
                cursor.execute("""
                    INSERT INTO dining_halls (id, name, url)
                    VALUES (%s, %s, %s)
                    ON CONFLICT (id) DO NOTHING
                """, (dining_hall_id, name, url))

            self.conn.commit()
        except Exception as e:
            self.logger.error(f"Error ensuring dining hall exists: {e}")
            self.conn.rollback()
            raise

    # ============================================
    # ALLERGEN MANAGEMENT
    # ============================================

    def get_or_create_allergen(self, allergen_name: str) -> int:
        """Get allergen ID or create if doesn't exist"""
        cursor = self.conn.cursor()

        try:
            if self.db_type == "sqlite":
                cursor.execute("""
                    INSERT OR IGNORE INTO allergens (allergen_name)
                    VALUES (?)
                """, (allergen_name,))
                self.conn.commit()

                cursor.execute("SELECT id FROM allergens WHERE allergen_name = ?", (allergen_name,))
                result = cursor.fetchone()
                return result[0] if isinstance(result, tuple) else result['id']

            elif self.db_type == "postgres":
                cursor.execute("""
                    INSERT INTO allergens (allergen_name)
                    VALUES (%s)
                    ON CONFLICT (allergen_name) DO NOTHING
                    RETURNING id
                """, (allergen_name,))

                result = cursor.fetchone()
                if result:
                    self.conn.commit()
                    return result[0]
                else:
                    cursor.execute("SELECT id FROM allergens WHERE allergen_name = %s", (allergen_name,))
                    return cursor.fetchone()[0]

        except Exception as e:
            self.logger.error(f"Error getting/creating allergen: {e}")
            self.conn.rollback()
            raise

    # ============================================
    # MENU INSERTION
    # ============================================

    def insert_scraped_menu(self, scraped_menu: Any) -> bool:
        """
        Insert complete scraped menu into database

        Args:
            scraped_menu: ScrapedMenu dataclass instance

        Returns:
            bool: Success status
        """
        cursor = self.conn.cursor()

        try:
            metadata = scraped_menu.scrape_metadata
            dining_hall_id = metadata['dining_hall_id']
            dining_hall_name = metadata['dining_hall_name']
            menu_date = date.fromisoformat(metadata['scrape_date'])
            scrape_timestamp = datetime.fromisoformat(metadata['scrape_timestamp'])

            self.logger.info(f"Inserting menu for {dining_hall_name} on {menu_date}")

            # Ensure dining hall exists
            # Note: You'll need to pass the URL separately or add it to metadata
            self.ensure_dining_hall_exists(dining_hall_id, dining_hall_name, "")

            # Create scrape run record
            if self.db_type == "sqlite":
                cursor.execute("""
                    INSERT OR REPLACE INTO scrape_runs
                    (dining_hall_id, menu_date, scrape_timestamp, status, items_scraped)
                    VALUES (?, ?, ?, ?, ?)
                """, (dining_hall_id, menu_date, scrape_timestamp, 'success', 0))
                scrape_run_id = cursor.lastrowid
            elif self.db_type == "postgres":
                cursor.execute("""
                    INSERT INTO scrape_runs
                    (dining_hall_id, menu_date, scrape_timestamp, status, items_scraped)
                    VALUES (%s, %s, %s, %s, %s)
                    ON CONFLICT (dining_hall_id, menu_date)
                    DO UPDATE SET scrape_timestamp = EXCLUDED.scrape_timestamp,
                                  status = EXCLUDED.status
                    RETURNING id
                """, (dining_hall_id, menu_date, scrape_timestamp, 'success', 0))
                scrape_run_id = cursor.fetchone()[0]

            total_items = 0

            # Insert meal periods, stations, and food items
            for meal in scraped_menu.meals:
                meal_period_id = self._insert_meal_period(
                    cursor, scrape_run_id, meal.meal_period, meal.meal_period_display
                )

                for station in meal.stations:
                    station_id = self._insert_station(
                        cursor, meal_period_id, station.station_name
                    )

                    for idx, food_item in enumerate(station.items):
                        # Get or create canonical food item
                        canonical_food_id = self.get_or_create_canonical_food_item(
                            dining_hall_id,
                            meal.meal_period,
                            station.station_name,
                            food_item.item_name,
                            menu_date
                        )

                        # Insert food item
                        food_item_id = self._insert_food_item(
                            cursor, station_id, food_item.item_name, idx, canonical_food_id
                        )

                        # Insert nutrition facts
                        if food_item.nutrition:
                            self._insert_nutrition_facts(cursor, food_item_id, food_item.nutrition)

                        # Insert allergens
                        for allergen_name in food_item.allergens:
                            allergen_id = self.get_or_create_allergen(allergen_name)
                            self._link_food_item_allergen(cursor, food_item_id, allergen_id)

                        total_items += 1

            # Update scrape run with total items
            param = '?' if self.db_type == "sqlite" else '%s'
            cursor.execute(f"""
                UPDATE scrape_runs
                SET items_scraped = {param}
                WHERE id = {param}
            """, (total_items, scrape_run_id))

            self.conn.commit()
            self.logger.info(f"Successfully inserted {total_items} items for {dining_hall_name}")
            return True

        except Exception as e:
            self.logger.error(f"Error inserting scraped menu: {e}")
            self.conn.rollback()
            return False

    def _insert_meal_period(self, cursor, scrape_run_id: int, meal_period: str, meal_period_display: str) -> int:
        """Insert meal period and return ID"""
        param = '?' if self.db_type == "sqlite" else '%s'
        cursor.execute(f"""
            INSERT INTO meal_periods (scrape_run_id, meal_period, meal_period_display)
            VALUES ({param}, {param}, {param})
        """, (scrape_run_id, meal_period, meal_period_display))
        return cursor.lastrowid if self.db_type == "sqlite" else cursor.fetchone()[0]

    def _insert_station(self, cursor, meal_period_id: int, station_name: str) -> int:
        """Insert station and return ID"""
        param = '?' if self.db_type == "sqlite" else '%s'
        cursor.execute(f"""
            INSERT INTO stations (meal_period_id, station_name)
            VALUES ({param}, {param})
        """, (meal_period_id, station_name))
        return cursor.lastrowid if self.db_type == "sqlite" else cursor.fetchone()[0]

    def _insert_food_item(self, cursor, station_id: int, item_name: str, display_order: int, canonical_food_id: int) -> int:
        """Insert food item and return ID"""
        param = '?' if self.db_type == "sqlite" else '%s'
        cursor.execute(f"""
            INSERT INTO food_items (station_id, item_name, display_order, canonical_food_id)
            VALUES ({param}, {param}, {param}, {param})
        """, (station_id, item_name, display_order, canonical_food_id))
        return cursor.lastrowid if self.db_type == "sqlite" else cursor.fetchone()[0]

    def _insert_nutrition_facts(self, cursor, food_item_id: int, nutrition):
        """Insert nutrition facts"""
        param = '?' if self.db_type == "sqlite" else '%s'
        cursor.execute(f"""
            INSERT INTO nutrition_facts (
                food_item_id, serving_size, calories, total_fat, saturated_fat, trans_fat,
                cholesterol, sodium, total_carbohydrate, dietary_fiber, sugars, protein,
                vitamin_a, vitamin_c, calcium, iron
            ) VALUES ({param}, {param}, {param}, {param}, {param}, {param}, {param}, {param}, {param}, {param}, {param}, {param}, {param}, {param}, {param}, {param})
        """, (
            food_item_id, nutrition.serving_size, nutrition.calories,
            nutrition.total_fat, nutrition.saturated_fat, nutrition.trans_fat,
            nutrition.cholesterol, nutrition.sodium, nutrition.total_carbohydrate,
            nutrition.dietary_fiber, nutrition.sugars, nutrition.protein,
            nutrition.vitamin_a, nutrition.vitamin_c, nutrition.calcium, nutrition.iron
        ))

    def _link_food_item_allergen(self, cursor, food_item_id: int, allergen_id: int):
        """Link food item to allergen"""
        param = '?' if self.db_type == "sqlite" else '%s'
        try:
            cursor.execute(f"""
                INSERT INTO food_item_allergens (food_item_id, allergen_id)
                VALUES ({param}, {param})
            """, (food_item_id, allergen_id))
        except:
            pass  # Ignore duplicate entries


# ============================================
# CONVENIENCE FUNCTIONS
# ============================================

def insert_menu_to_database(scraped_menu: Any, db_type: str = "sqlite", db_path: Optional[str] = None) -> bool:
    """
    Convenience function to insert a scraped menu into the database

    Args:
        scraped_menu: ScrapedMenu instance
        db_type: "sqlite" or "postgres"
        db_path: Path to SQLite database (if using SQLite)

    Returns:
        bool: Success status
    """
    with DatabaseManager(db_type=db_type, db_path=db_path) as db:
        return db.insert_scraped_menu(scraped_menu)
