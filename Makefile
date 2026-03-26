all:
	ninja -C build

setup:
	meson setup build

clean:
	rm -rf build

fmt:
	io.elementary.vala-lint --fix

run: all
	./build/apps/$(filter-out $@,$(MAKECMDGOALS))/$(filter-out $@,$(MAKECMDGOALS))

%:
	@:
