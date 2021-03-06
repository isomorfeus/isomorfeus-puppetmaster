Isomorfeus::Puppetmaster.register_driver(:chromium) do |app|
  Isomorfeus::Puppetmaster::Driver::Puppeteer.new(browser_type: :chromium, headless: true, app: app)
end

Isomorfeus::Puppetmaster.register_driver(:chromium_wsl) do |app|
  Isomorfeus::Puppetmaster::Driver::Puppeteer.new(browser_type: :chromium, headless: true, app: app, args: ['--no-sandbox'])
end

Isomorfeus::Puppetmaster.register_driver(:chromium_debug) do |app|
  Isomorfeus::Puppetmaster::Driver::Puppeteer.new(browser_type: :chromium, headless: false, devtools: true, app: app)
end
