
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ptmismatch

<!-- badges: start -->
<!-- badges: end -->

The goal of ptmismatch is to find and summarize primer binding sites
within a given set of sequences to estimate priming efficiency during a
polymerase chain reaction (PCR).

## Installation

You can install the development version of ptmismatch from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("medvir/ptmismatch")
```

## Example

For now, ptmismatch only contains one function. `find_matches()` can be
used to find primer-template matches. Load the package and open the
documentation as follows:

``` r

library(ptmismatch)

?find_matches()
```

A primer (or pattern) and template (or subject) sequence is required.
The primer sequence can be provided as string. [IUPAC ambiguity
codes](https://www.bioinformatics.org/sms/iupac.html) are supported
(e.g. “R” matches “A” and “G”). “I” are not supported, replace them with
“N” instead.

The template sequence(s) can be read from a fasta file using the
`Biostrings::readDNAStringSet()` function.

``` r

EV_fwd <- "GCTGCGYTGGCGGCC"

EV_sequences_fasta <- system.file("extdata", "Enterovirus_12059.fasta", package="ptmismatch")

EV_sequences <- Biostrings::readDNAStringSet(EV_sequences_fasta)
```

Search either just one specific sequence…

``` r

find_matches(pattern = EV_fwd, subject = EV_sequences, subject_index = 1,
             max.mismatch = 1, with.indels = TRUE)
#> # A tibble: 1 × 6
#>   seqID      pattern         strand start   end matched       
#>   <chr>      <chr>           <chr>  <int> <dbl> <chr>         
#> 1 GQ865517.1 GCTGCGYTGGCGGCC +        359   372 CTGCGTTGGCGGCC
```

…or all sequences within a fasta file.

``` r

purrr::map_dfr(1:length(EV_sequences),
               function(x) find_matches(pattern = EV_fwd, subject = EV_sequences, subject_index = x,
                                        max.mismatch = 1, with.indels = TRUE))
#> # A tibble: 20 × 6
#>    seqID       pattern         strand start   end matched        
#>    <chr>       <chr>           <chr>  <int> <dbl> <chr>          
#>  1 GQ865517.1  GCTGCGYTGGCGGCC +        359   372 CTGCGTTGGCGGCC 
#>  2 JN542510.1  GCTGCGYTGGCGGCC +        361   375 GCTGCGTTGGCGGCC
#>  3 JX514942.1  GCTGCGYTGGCGGCC +        340   354 GCTGCGTTGGCGGCC
#>  4 JX393302.1  GCTGCGYTGGCGGCC +        332   345 CTGCGTTGGCGGCC 
#>  5 JX961708.1  GCTGCGYTGGCGGCC +        360   373 CTGCGTTGGCGGCC 
#>  6 KC344833.1  GCTGCGYTGGCGGCC +        308   322 GCTGCGTTGGCGGCC
#>  7 KC785528.1  GCTGCGYTGGCGGCC +        316   330 GCTGCGTTGGCGGCC
#>  8 KC785530.1  GCTGCGYTGGCGGCC +        297   311 GCTGCGTTGGCGGCC
#>  9 KF990476.1  GCTGCGYTGGCGGCC +        362   376 GCTGCGCTGGCGGCC
#> 10 KF312882.1  GCTGCGYTGGCGGCC +        362   376 GCTGCGTTGGCGGCC
#> 11 KJ420749.1  GCTGCGYTGGCGGCC +        362   376 GCTGCGTTGGCGGCC
#> 12 NC_024073.1 GCTGCGYTGGCGGCC +        362   376 GCTGCGTTGGCGGCC
#> 13 KU587555.1  GCTGCGYTGGCGGCC +        378   391 CTGCGTTGGCGGCC 
#> 14 NC_029905.1 GCTGCGYTGGCGGCC +        378   391 CTGCGTTGGCGGCC 
#> 15 KU355876.1  GCTGCGYTGGCGGCC +        367   381 GCTGCGTTGGCGGCC
#> 16 KU355877.1  GCTGCGYTGGCGGCC +        364   378 GCTGCGTTGGCGGCC
#> 17 NC_030454.1 GCTGCGYTGGCGGCC +        367   381 GCTGCGTTGGCGGCC
#> 18 NC_038306.1 GCTGCGYTGGCGGCC +        362   376 GCTGCGTTGGCGGCC
#> 19 NC_038307.1 GCTGCGYTGGCGGCC +        362   376 GCTGCGTTGGCGGCC
#> 20 NC_038308.1 GCTGCGYTGGCGGCC +        360   374 GCTGCGTTGGCGGCC
```
