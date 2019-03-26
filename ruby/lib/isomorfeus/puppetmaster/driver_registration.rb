Isomorfeus::Puppetmaster.register_driver(:chromium) do |app|
  Isomorfeus::Puppetmaster::Puppeteer.new(browser_type: :chromium, headless: true, app: app)
end

Isomorfeus::Puppetmaster.register_driver(:chromium_debug) do |app|
  Isomorfeus::Puppetmaster::Puppeteer.new(browser_type: :chromium, headless: false, devtools: true, app: app)
end

Isomorfeus::Puppetmaster.register_driver(:firefox) do |app|
  Isomorfeus::Puppetmaster::Puppeteer.new(browser_type: :firefox, headless: true, app: app)
end

Isomorfeus::Puppetmaster.register_driver(:firefox_debug) do |app|
  Isomorfeus::Puppetmaster::Puppeteer.new(browser_type: :firefox, headless: false, devtools: true, app: app)
end

Isomorfeus::Puppetmaster.register_driver(:jsdom) do |app|
  Isomorfeus::Puppetmaster::Jsdom.new(app: app)
end
