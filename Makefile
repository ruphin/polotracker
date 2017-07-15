dev:
	docker run -it --rm -v $$PWD:/app ruphin/rubydev bash
.PHONY: dev

production:
	docker run --rm -v $$PWD:/app ruphin/rubydev echo "BUNDLED GEMS"
	docker build -t ruphin/datavacuum .
	docker push ruphin/datavacuum
