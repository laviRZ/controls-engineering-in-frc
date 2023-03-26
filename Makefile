NAME := controls-engineering-in-frc

# Make does not offer a recursive wildcard function, so here's one:
rwildcard=$(wildcard $1$2) $(foreach dir,$(wildcard $1*),$(call rwildcard,$(dir)/,$2))

# C++ files that generate SVG files
CPP := $(filter-out ./bookutil/% ./build/% ./lint/% ./snippets/%,$(call rwildcard,./,*.cpp))
CPP_EXE := $(addprefix build/,$(CPP:.cpp=))

# Python files that generate SVG files
PY := $(filter-out ./bookutil/% ./build/% ./lint/% ./setup_venv.py ./snippets/%,$(call rwildcard,./,*.py))
PY_STAMP := $(addprefix build/,$(PY:.py=.stamp))

TEX := $(filter-out ./controls-engineering-in-frc-ebook.tex ./controls-engineering-in-frc-printer.tex,$(call rwildcard,./,*.tex))
BIB := $(wildcard *.bib)
EBOOK_IMGS := $(addprefix build/controls-engineering-in-frc-ebook/,$(wildcard imgs/*))
PRINTER_IMGS := $(addprefix build/controls-engineering-in-frc-printer/,$(wildcard imgs/*))
SNIPPETS := $(wildcard snippets/*)

CSV := $(filter-out ./bookutil/% ./build/% ./lint/% ./snippets/%,$(call rwildcard,./,*.csv))
CSV := $(addprefix build/,$(CSV))

ifeq ($(OS),Windows_NT)
	CONVERT := magick convert
	VENV_PYTHON := ./build/venv/Scripts/python3
	VENV_PIP := ./build/venv/Scripts/pip3
else
	CONVERT := convert
	VENV_PYTHON := ./build/venv/bin/python3
	VENV_PIP := ./build/venv/bin/pip3
endif

.PHONY: all
all: ebook

.PHONY: ebook
ebook: $(NAME)-ebook.pdf

.PHONY: printer
printer: $(NAME)-printer.pdf

$(NAME)-ebook.pdf: $(TEX) $(NAME)-ebook.tex $(CPP_EXE) $(PY_STAMP) \
		$(BIB) $(EBOOK_IMGS) $(SNIPPETS) build/commit-date.tex \
		build/commit-year.tex build/commit-hash.tex
	latexmk -interaction=nonstopmode -xelatex $(NAME)-ebook

$(NAME)-printer.pdf: $(TEX) $(NAME)-printer.tex $(CPP_EXE) $(PY_STAMP) \
		$(BIB) $(PRINTER_IMGS) $(SNIPPETS) build/commit-date.tex \
		build/commit-year.tex build/commit-hash.tex
	latexmk -interaction=nonstopmode -xelatex $(NAME)-printer

$(EBOOK_IMGS): build/controls-engineering-in-frc-ebook/%.jpg: %.jpg
	@mkdir -p $(@D)
# 150dpi, 75% quality
# cover: 4032x2016 -> 150dpi * 8.5" x 150dpi * 11" -> 1275x1650
# banners: 4032x2016 -> 150dpi * 8.5" x 150dpi * 4.25" -> 1275x637
	if [ "$<" = "imgs/cover.jpg" ]; then \
		$(CONVERT) "$<" -resize 1275x1650 -quality 75 "$@"; \
	else \
		$(CONVERT) "$<" -resize 1275x637 -quality 75 "$@"; \
	fi

$(PRINTER_IMGS): build/controls-engineering-in-frc-printer/%.jpg: %.jpg
	@mkdir -p $(@D)
# 300dpi, 95% quality
# cover: 4032x2016 -> 300dpi * 8.5" x 300dpi * 11" -> 2550x3300
# banners: 4032x2016 -> 300dpi * 8.5" x 300dpi * 4.25" -> 2550x1275
	if [ "$<" = "imgs/cover.jpg" ]; then \
		$(CONVERT) "$<" -resize 2550x3300 -quality 95 "$@"; \
	else \
		$(CONVERT) "$<" -resize 2550x1275 -quality 95 "$@"; \
	fi

build/commit-date.tex: .git/refs/heads/$(shell git rev-parse --abbrev-ref HEAD) .git/HEAD
	@mkdir -p $(@D)
	git log -1 --pretty="format:%ad" --date="format:%B %-d, %Y" > build/commit-date.tex

build/commit-year.tex: .git/refs/heads/$(shell git rev-parse --abbrev-ref HEAD) .git/HEAD
	@mkdir -p $(@D)
	git log -1 --pretty="format:%ad" --date="format:%Y" > build/commit-year.tex

build/commit-hash.tex: .git/refs/heads/$(shell git rev-parse --abbrev-ref HEAD) .git/HEAD
	@mkdir -p $(@D)
	echo "\href{https://github.com/calcmogul/$(NAME)/commit/`git rev-parse --short HEAD`}{commit `git rev-parse --short HEAD`}" > build/commit-hash.tex

# This rule places CSVs into the build folder so scripts executed from the build
# folder can use them.
$(CSV): build/%.csv: %.csv
	@mkdir -p $(@D)
	cp $< $@

build/venv.stamp:
	@mkdir -p $(@D)
	python3 setup_venv.py
	$(VENV_PIP) install -e ./bookutil
	$(VENV_PIP) install frccontrol==2023.26 pylint requests robotpy-wpimath==2023.4.2
	@touch $@

$(CPP_EXE): build/%: %.cpp build/venv.stamp
	@mkdir -p $(@D)
	# Run CMake
	cmake -B $(@D) -S $(dir $<)
	# Build and run binary
	cmake --build $(@D)
	cd $(@D) && ./$(notdir $(basename $<))
	# Convert generated CSVs to PDFs
	$(abspath $(VENV_PYTHON)) ./snippets/sleipnir_csv_to_pdf.py $(@D)/*.csv

$(PY_STAMP): build/%.stamp: %.py $(CSV) build/venv.stamp
	@mkdir -p $(@D)
	cd $(@D) && $(abspath $(VENV_PYTHON)) $(abspath ./$<) --noninteractive
	@touch $@

# Run formatters
.PHONY: format
format: build/venv.stamp
	./lint/format_bibliography.py
	./lint/format_eol.py
	./lint/format_paragraph_breaks.py
	cd snippets && clang-format -i *.cpp
	python3 -m black -q .
	git --no-pager diff --exit-code HEAD  # Ensure formatters made no changes

# Run formatters and all linters except link checker. The commit metadata files
# and files generated by Python scripts are dependencies because
# check_tex_includes.py will fail if they're missing.
.PHONY: lint_no_linkcheck
lint_no_linkcheck: format build/commit-date.tex build/commit-year.tex build/commit-hash.tex $(PY_STAMP)
	find . -type f -name '*.py' -print0 | xargs -0 $(abspath ./build/venv/bin/python3) -m pylint
	./lint/check_filenames.py
	./lint/check_tex_includes.py
	./lint/check_tex_labels.py

# Run formatters and linters
.PHONY: lint
lint: lint_no_linkcheck
	./lint/check_links.py

.PHONY: clean
clean: clean_tex
	rm -rf build

.PHONY: clean_tex
clean_tex:
	latexmk -xelatex -C
	rm -f controls-engineering-in-frc-*.pdf

.PHONY: upload
upload: upload_ebook upload_printer

.PHONY: upload_ebook
upload_ebook: ebook
	rsync --progress $(NAME)-ebook.pdf file.tavsys.net:/srv/file/control/$(NAME).pdf

.PHONY: upload_printer
upload_printer: printer
	rsync --progress $(NAME)-printer.pdf file.tavsys.net:/srv/file/control/$(NAME)-printer.pdf

.PHONY: setup_archlinux
setup_archlinux:
	sudo pacman -Sy --needed --noconfirm \
		base-devel \
		biber \
		clang \
		cmake \
		imagemagick \
		inkscape \
		perl-clone \
		python \
		python-black \
		python-pip \
		python-pylint \
		python-requests \
		python-wheel \
		texlive-bibtexextra \
		texlive-core \
		texlive-latexextra

.PHONY: setup_ubuntu
setup_ubuntu:
	sudo apt-get update -y
	sudo apt-get install -y \
		biber \
		build-essential \
		cm-super \
		clang-format \
		cmake \
		dvipng \
		imagemagick \
		inkscape \
		latexmk \
		python3 \
		python3-pip \
		python3-requests \
		python3-setuptools \
		python3-wheel \
		texlive-base \
		texlive-bibtex-extra \
		texlive-latex-extra \
		texlive-xetex
# The Ubuntu 22.04 packages are too old
	pip3 install --user black pylint

.PHONY: setup_macos
setup_macos:
	brew install \
		basictex \
		clang-format \
		cmake \
		imagemagick \
		inkscape
	sudo /Library/TeX/texbin/tlmgr update --self
	sudo /Library/TeX/texbin/tlmgr install \
		biber \
		biblatex \
		cm-super \
		csquotes \
		datatool \
		enumitem \
		footmisc \
		gensymb \
		glossaries \
		glossaries-english \
		imakeidx \
		latexmk \
		mdframed \
		mfirstuc \
		needspace \
		placeins \
		titlesec \
		tracklang \
		type1cm \
		was \
		xfor \
		zref
	pip3 install --user black pylint requests wheel
