from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chromium.options import ChromiumOptions
from selenium.webdriver.common.by import By
import time

from selenium.webdriver.ie.webdriver import WebDriver


def scrape_website() -> dict:

	menus = [
		"https://dining.umich.edu/menus-locations/dining-halls/bursley/",
		"https://dining.umich.edu/menus-locations/dining-halls/east-quad/",
		"https://dining.umich.edu/menus-locations/dining-halls/markley/",
		"https://dining.umich.edu/menus-locations/dining-halls/mosher-jordan/",
		"https://dining.umich.edu/menus-locations/dining-halls/north-quad/",
		"https://dining.umich.edu/menus-locations/dining-halls/south-quad/",
		"https://dining.umich.edu/menus-locations/dining-halls/twigs-at-oxford/",
	]
	path: str = "/Users/alex/Downloads/chromedriver-mac-arm64-2/chromedriver"
	op: ChromiumOptions = webdriver.ChromeOptions()
	# op.add_argument('headless')
	service: Service = Service(executable_path=path)
	driver: WebDriver = webdriver.Chrome(service=service, options=op)
    

	driver.get("https://dining.umich.edu/menus-locations/dining-halls/bursley/")
	item = []                                                                 #here
	meal = "/html/body/div[1]/div[3]/div[1]/div/div/div[1]/div/div/div[2]/div[1]/h3[1]/a"
	foodList = "/html/body/div[1]/div[3]/div[1]/div/div/div[1]/div/div/div[2]/div[1]/div[2]/ul/li[1]/ul/li[1]/a"
	food = "/html/body/div[1]/div[3]/div[1]/div/div/div[1]/div/div/div[2]/div[1]/div[2]/ul/li[1]/ul/li[1]/div/div[2]/table/tbody/tr[14]/td[1]/strong"
	for i in range(1, 4):
		meal = f"/html/body/div[1]/div[3]/div[1]/div/div/div[1]/div/div/div[2]/div[1]/h3[{i}]/a"
		driver.find_element(By.XPATH, meal).click()
	time.sleep(0.5)
	driver.find_element(By.XPATH, foodList).click()
	time.sleep(0.5)
	item.append(driver.find_element(By.XPATH, food).text)
	print(item)
	while True:
		time.sleep(1)

	# for url in menus:
	# 	driver.get(url)


	return {}

if __name__ == "__main__":
	scrape_website()
