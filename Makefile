# Copyright 2018 Adobe
# All Rights Reserved.

# NOTICE: Adobe permits you to use, modify, and distribute this file in
# accordance with the terms of the Adobe license agreement accompanying
# it. If you have received this file from a source other than Adobe,
# then your use, modification, or distribution of it requires the prior
# written permission of Adobe.

# Define the tools folder
TOOLS_FOLDER := tools

# Find all tools in the $TOOLS_FOLDER folder and returns a list of "make go git" etc
TOOLS := $(shell find ${TOOLS_FOLDER} -mindepth 1 -maxdepth 1 -type d | sed -e "s;^${TOOLS_FOLDER}/;;")

# define the targets available
steps := check clean build verify release update

# Dependencies of each step
tgt_dep_check = eat_dog_food
tgt_dep_update = eat_dog_food
tgt_dep_clean = $1.check
tgt_dep_build = $1.clean
tgt_dep_verify = $1.build
tgt_dep_release = $1.verify

# define a generic block to generate some rules on the fly
# Will get the name of the tool and the name of step as an argument
# Will then dispatch the call to the make.sh file 
# with the action as first argument and the tool name as second
define make-tool-target
.PHONY: $1.$2
$1.$2: $(tgt_dep_$2)
	@./make.sh $2 $1
endef

# Set the default target to make
.DEFAULT_GOAL := all
.PHONY: all
all: prb

# `prb` is the default target and assumes to check the tools like in a pull request
.PHONY: prb
prb: $(foreach tool,$(TOOLS),$(addprefix $(tool).,verify))

# `ci` is the release target, additionally to the prb steps it will push the images and tag the release
.PHONY: ci
ci: $(foreach tool,$(TOOLS),$(addprefix $(tool).,release))

# `update` is the target that will check each tool for updates (if possible)
.PHONY: update
update: $(foreach tool,$(TOOLS),$(addprefix $(tool).,update))

# Will set up the requirements for working, aka. installing sledgehammer
.PHONY: eat_dog_food
eat_dog_food:
	@./make.sh eat_dog_food

# generate targets for all steps
$(foreach tool,$(TOOLS),$(foreach step,$(steps),$(eval $(call make-tool-target,$(tool),$(step)))))