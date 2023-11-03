# ycbcr_proyect

## Tested

### Ripple Carry Adder

![Alt text](docs/images/ripple_carry_adder_48_tb.png)

## Next tasks

-   ~~Test the 24 bit ripple_carry_adder~~
-   ~~Test the 48 bit ripple_carry_adder~~
-   Work on the Braun multiplier and try to fix it and find in the internet a version of it that is extensible for varaiblae inputs
-   Add sign logic to the multiplier
-   try the most basic version with the the multiplier and the adder and then try other types of block to try to find a more optimal design
-   Uniform the naming of variables and files

-   ASK: how to convert the coefficients to csd number

## Presentation

-   Talk about how at the first time I tried the ripple carrie adder was instiated in every loop so i change the algorithm again
-   Talk how the code uses alot of resources and it should be optimized
    -   Use the Booth multipler that takes into account the sing [Booth multiplier](https://github.com/gustavohb/booth-multiplier/blob/master/booth_multiplier.vhd)
