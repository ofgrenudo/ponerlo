# Ponerlo

Ponerlo is a tool to take device information, and on run upload it to the SnipeIT asset inventory system. This project is currently still in its very early stages and is being actively worked on.

## Roadmap

The point of the roadmap is to keep this project on track. Here we will outline our goals and what we would like to see from the application. As time goes, this may change and or be updated. 

- [x] Collect Information from Local Machine...
- [x] Check Snipe for device with Existing Serial Number or Asset Tag.
- [ ] Insert the record
    - [ ] If the device does exist, PUT the record.
    - [ ] If the device does not exist, POST the record.
        - [x] Generate correct model, and category.

Possible redundancy later on in the line could be to double book the information into MECM if possible.

Currently, the goal is to just *get it working*. Long term, the Idea would be to rebase this and write it in Rust. Rust is the chosen language for its inherient saftey, and strongly typed features. As well as the fact that it compiles down into a native binary, making for easy distrubtion...

## Contributing

As you contribute to this project, it is expected that you handle a bug or an issue as a feature branch. That branch should contain the one issue, or major failure that you are experienceing. And then be pushed to the main branch.

If you are working on a Roadmap issue, your branch may deviate more drastically than a minor bug, which is okay. But still should only contain code that is consistent with the issue you are trying to solve.