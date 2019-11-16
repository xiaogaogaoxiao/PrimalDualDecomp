# PrimalDualDecomp
This code (and data) accompanies the paper 
"Primal-dual decomposition by operator splitting and applications to image deblurring"  
by Daniel O'Connor and Lieven Vandenberghe
(www.seas.ucla.edu/~vandenbe/publications).

All experiments in the paper can be reproduced with this code.

If you have any questions about this code please feel free to email 
daniel.v.oconnor@gmail.com.

Section 3.5 (including Figure 1) can be reproduced using test_testProblem.m.

Section 5.1 (including Figure 2) can be reproduced using
test_simpleTV.m.

Section 5.2 (including Figure 4) can be reproduced using
test_mixedTV.m.

Section 6.1 (including Figure 6) can be reproduced using
test_simpleTightFrame.m.

Section 6.2 (including Figure 8) can be reproduced using
test_mixedTightFrame.m.

Section 7 (including Figure 10) can be reproduced using test_mixedTV_decomp.m.

The tight frame examples (test_simpleTightFrame.m and 
test_mixedTightFrame.m) use Shearlab-1.1, which can be found at 
http://www.shearlab.org/index_software.html

If you're trying to reproduce the figures in the paper and you don't want 
to wait for Douglas-Rachford to run for 10,000 iterations, you can use the 
minPrimal variable which is stored in the files:

minPrimal_simpleTV_10KDRiters.mat
minPrimal_mixedTV_10KDRiters.mat
minPrimal_simpleTightFrame_10KDRiters.mat
minPrimal_mixedTightFrame_10KDRiters.mat
minPrimal_mixedTV_decomp_DR10k.mat

minPrimal contains the primal objective function value after 10,000 
iterations of Douglas-Rachford.  
minPrimal is called f^\star in the figures in the paper.
