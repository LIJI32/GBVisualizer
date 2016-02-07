visualizer.gbc: visualizer.o
	rgblink -o $@ -m visualizer.map -n visualizer.sym $<
	rgbfix -Cv -i GBVP -t "GBvisualizer" -m 25 $@
CLEAN += visualizer.gbc visualizer.sym visualizer.map

visualizer.o: visualizer.asm music.gbm gbhw.asm
	rgbasm -o $@ $<
CLEAN += visualizer.o

music.gbm: music.itt
	python itt.py $< > $@
CLEAN += music.gbm

clean:
	rm $(CLEAN)