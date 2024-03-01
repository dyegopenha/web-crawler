# This Ruby data scraper analyzes a web page, searches for new links, 
# adds them to the crawling queue and scrapes data from the current page. 
# Then it repeats this logic for each page.

# The script will visit the entire website (accordingly to the limit) 
# and pages_discovered will store the pagination URLs. As a result, 
# output.csv will contain the data of the Pokemon-inspired products
# on the website.

require "httparty"
require "nokogiri"

# defining a data structure to store the scraped data
PokemonProduct = Struct.new(:url, :image, :name, :price)

# initializing the list of objects
# that will contain the scraped data
pokemon_products = []

# initializing the list of pages to scrape with the
# pagination URL associated with the first page
pages_to_scrape = ["https://scrapeme.live/shop/page/1/"]

# initializing the list of pages discovered
# with a copy of pages_to_scrape
pages_discovered = ["https://scrapeme.live/shop/page/1/"]

# current iteration
i = 0

# max pages to scrape
limit = 5

# iterate until there is still a page to scrape
# or the limit is reached
while pages_to_scrape.length != 0 && i < limit do
    # getting the current page to scrape and removing it from the list
    page_to_scrape = pages_to_scrape.pop

    # retrieving the current page to scrape
    response = HTTParty.get(page_to_scrape, {
        headers: {
            "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) 
            AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"
        },
    })

    # parsing the HTML document returned by the server
    document = Nokogiri::HTML(response.body)

    # extracting the list of URLs from the pagination elements
    pagination_links = document
                        .css("a.page-numbers")
                        .map{ |a| a.attribute("href") }

    # iterating over the list of pagination links
    pagination_links.each do |new_pagination_link|
        # if the web page discovered is new and should be scraped
        if !(pages_discovered.include? new_pagination_link) && 
            !(pages_to_scrape.include? new_pagination_link)
            pages_to_scrape.push(new_pagination_link)
        end
        # discovering new pages
        pages_discovered.push(new_pagination_link)
    end

    #removing the duplicated elements
    pages_discovered = pages_discovered.to_set.to_a

    # selecting all HTML product elements
    html_products = document.css("li.product")

    # iterating over the list of HTML products
    html_products.each do |html_product|
        # extracting the data of interest
        # from the current product HTML element
        url = html_product.css("a").first.attribute("href").value
        image = html_product.css("img").first.attribute("src").value
        name = html_product.css("h2").first.text
        price = html_product.css("span").first.text
        # storing the scraped data in a PokemonProduct object
        pokemon_product = PokemonProduct.new(url, image, name, price)
        # adding the PokemonProduct to the list of scraped objects
        pokemon_products.push(pokemon_product)
    end
    
    # incrementing the iteration counter
    i = i + 1
end

# defining the header row of the CSV file
csv_headers = ["url", "image", "name", "price"]
CSV.open("output.csv", "wb", write_headers: true, headers: csv_headers) do |csv|
    # adding each pokemon_product as a new row to the output CSV file
    pokemon_products.each do |pokemon_product|
        csv << pokemon_product
    end
end