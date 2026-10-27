# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/lib", under: "lib"
pin "@googlemaps/markerclusterer", to: "@googlemaps--markerclusterer.js" # @2.6.2
pin "fast-equals" # @5.4.5
pin "kdbush" # @4.1.0
pin "supercluster" # @8.0.1
