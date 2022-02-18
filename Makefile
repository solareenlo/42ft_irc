# Makefile for ft_containers, updated Tue Nov 30 06:50:22 JST 2021

SRC := main.cpp
OBJ := main.o
DEP := main.d

# DO NOT ADD OR MODIFY ANY LINES ABOVE THIS -- run 'make source' to add files

NAME      := ircserv

CXX        = clang++
CFLAGS    := -Wall -Wextra -Werror -std=c++98 -pedantic-errors
RM        := rm -fr
DFLAGS	   = -MMD -MP

SRC_DIR   := .
OBJ_DIR   := ./obj
SRCS      := $(addprefix $(SRC_DIR)/, $(SRC))
OBJS      := $(addprefix $(OBJ_DIR)/, $(SRC:.cpp=.o))
DEPS      := $(addprefix $(OBJ_DIR)/, $(SRC:.cpp=.d))
HEADERS   := $(shell find . -not -path "./.ccls-cache/*" -type f -name '*.hpp' -print)
CPPLINT_FILTERS := --filter=-legal/copyright,-runtime/references,-build/include_what_you_use,-runtime/int
COVERAGE  := coverage
EXE_ARG   := 100
UNIT_TEST := unit_test

UNAME_S   := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	CFLAGS += -D LINUX
endif

-include $(DEPS)

.PHONY:	all
all: $(NAME)

# Linking
$(NAME): $(OBJS)
	$(CXX) $(CFLAGS) -o $@ $^

# Compiling
$(OBJ_DIR)/%_std.o: $(SRC_DIR)/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CFLAGS) -o $@ -c $< $(DFLAGS)

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CFLAGS) -o $@ -c $< $(DFLAGS)

.PHONY: lint
lint:
	cpplint --recursive $(CPPLINT_FILTERS) $(SRC) $(HEADERS)

.PHONY: leak
leak: CFLAGS += -g -fsanitize=leak
leak: test

.PHONY: address
address: CFLAGS += -g -fsanitize=address
address: test

.PHONY: thread
thread: CFLAGS += -g -fsanitize=thread
thread: test

.PHONY: memory
memory: CFLAGS += -g -fsanitize=memory
memory: test

.PHONY: gcov
gcov: CXX      = g++
gcov: CFLAGS   += -fPIC -fprofile-arcs -ftest-coverage
gcov: re
	./$(NAME)
	gcov -o $(OBJ_DIR) $(SRCS)

.PHONY: lcov
lcov: gcov
	mkdir -p ./$(COVERAGE)
	lcov --capture --directory . --output-file ./$(COVERAGE)/lcov.info

.PHONY: report
report : lcov
	genhtml ./$(COVERAGE)/lcov.info --output-directory ./$(COVERAGE)

.PHONY: clean
clean:
	$(RM) Makefile.bak $(NAME).dSYM $(OBJ_DIR)
	$(RM) *.so *.gcno *.gcda *.gcov *.info $(COVERAGE)

.PHONY: fclean
fclean: clean
	$(RM) $(NAME)

.PHONY: re
re: fclean all

.PHONY: valgrind
valgrind: re
	valgrind --leak-check=full --show-leak-kinds=all --track-fds=yes ./$(NAME)

.PHONY: test
test: re
	./$(NAME)

.PHONY: source
source:
	@mv Makefile Makefile.bak
	@echo "# Makefile for ft_containers, updated `date`" >> Makefile
	@echo '' >> Makefile
	@echo SRC := `ls *.cpp` >> Makefile
	@echo OBJ := `ls *.cpp | sed s/cpp$$/o/` >> Makefile
	@echo DEP := `ls *.cpp | sed s/cpp$$/d/` >> Makefile
	@echo '' >> Makefile
	@sed -n -e '/^# DO NOT ADD OR MODIFY/,$$p' < Makefile.bak >> Makefile
