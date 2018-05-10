;+
; NAME: mk_mass
;
; PURPOSE: Calculate a mass posterior given an input K magnitude and distance
;          Based on The M_{K_S}-Mass relation from Mann et al. (2018b).
;          
;          http://adsabs.harvard.edu/abs/PAPER
;
; CALLING SEQUENCE:  mass = mk_mass(K,dist,eK,edist,feh=feh,efeh=efeh,
;                                   /oned,/silent)
;
; INPUTS:
;          K:     2MASS Ks-band (magnitudes)
;          dist:  distance (parsecs)
;          ek:    error on K (magnitudes). If not provided assumed to be 0
;          edist: error on distance (parcsecs). If not provided assumed to be 0
;
; OPTIONAL INPUTS:  
;          feh:  Iron abundance. If provided the code will use the
;                Mk-Mass-[Fe/H] relation instead
;          efeh: error on iron abundance (dex). If not provided, but feh
;                is provied, assumed to be 0
;
;
; KEYWORD PARAMETERS:
;          oned:  Returns a simple 1D error instead of a posterior
;
;          silent: surpress the many warnings
;
; OUTPUTS:
;          mass: if /oned is set this is a 2-element array containing the
;                median and standard deviation of the mass posterior. Else
;                this contains the posterior on mass
;
; EXAMPLE:
;    Create a color table of only greens and plot to the screen
;          IDL> 
;
; MODIFICATION HISTORY:
;          May 10 2018: Ported from scratch code by A. Mann
;         
;
;If you use this code, please cite the relevant paper:
;
;-

function mk_mass,k,dist,ek,edist,feh=feh,efeh=efeh,silent=silent

  if n_elements(silent) eq 0 then silent = 0
  if n_elements(ek) eq 0 then begin
     if silent eq 0 then print,'Warning, assuming no error on K, mass errors underestimated'
     ek = 0d0*k
  endif
  if n_elements(edist) eq 0 then begin
     if silent eq 0 then print,'Warning, assuming no error on distance, mass errors underestimated'
     edist = 0d0*k
  endif
  if n_elements(efeh) eq 0 and n_elements(feh) gt 0 then begin
     if silent eq 0 then print,'Warning, assuming no error on [Fe/H], mass errors underestimated'
     efeh = 0d0*feh
  endif
  if n_elements(k) lt 1 or n_elements(ek) lt 1 or n_elements(dist) lt 1 or n_Elements(edist) lt 1 or n_elements(k) ne n_elements(ek) or n_elements(dist) ne n_elements(edist) or n_elements(k) ne n_elements(dist) or n_elements(feh) ne n_elements(efeh) then begin
     if silent eq 0 then print,'mk_mass,kmag,ekmag,distance,dist_err; all input must be the same size'
     return,-1
  endif
  if n_elements(feh) gt 0 and n_elements(feh) ne n_elements(k) then begin
     if silent eq 0 then print,'If [Fe/H] is provided as an array, it must have the same size as other parameters'
     return,-1
  endif

  ;; this needs to be able to handle a few different scenarios:
  ;; 1) the input values are scalars
  ;; 2) the input values are vectors, smaller than the posteriors on Mk-Mass (truncate ours randomly)
  ;; 3) the input values are vectors, larger than the posteriors on Mk-Mass (expand ours to match)
  
  mcmc = mrdfits('~/Dropbox/Post_ML/Mk-M_5_chain.fits',/silent)
  x = mcmc
  ntot = n_elements(x[0,*,*])
  a = reform(x[0,*,*],ntot)
  b = reform(x[1,*,*],ntot)
  c = reform(x[2,*,*],ntot)
  d = reform(x[3,*,*],ntot)
  e = reform(x[4,*,*],ntot)
  m = dblarr(n_elements(k))
  if n_elements(k) eq 1 then begin
     kmag = k+ek*randomn(seed,n_elements(a))
     distance = dist + edist*randomn(seed,n_elements(a))
     mk = kmag-5d0*(alog10(distance)-1d0)
     mass = 10d0^(a+b*(mk-7.5d0)+c*(mk-7.5d0)^2d0+d*(mk-7.5d0)^3d0+e*(mk-7.5d0)^4d0)
     m = mass
  endif
  return,m
  
end


;; This is a small code to help test the output of the mk_mass code
;; It just runs a few well-known systems (mostly planet hosts) and
;; checkes how the masses compare to semi-independent determinations
;; (e.g., using models, transit-fit density, etc.)
PRO tester

;; trappist-1
  k = 10.296
  ek = 0.023
  dist = 12.136
  edist = 0.118
  mass = mk_mass(k,ek,dist,edist)
  cghistoplot,mass,/outline,thick=3
  print,median(mass),stdev(mass)

  mVG = 0.089+0.006*randomn(seed,n_elements(mass))
  cghistoplot,mass-mVG,/outline,thick=3
  print,median(mass-mVG),stdev(mass-mVG),median(mass-mVG)/stdev(mass-mVG)
  ;; value reported by Van Grootel et al.:
  ;; 0.089 +/- 0.006
  ;; we get 0.0889 +/- 0.004


  ;;GJ1214
  k = 8.782
  ek = 0.02
  dist = 14.55
  edist = 0.13
  mass = mk_mass(k,ek,dist,edist)
  print,median(mass),stdev(mass)
  mAE = 0.176+0.009*randomn(seed,n_elementS(mass))
  cghistoplot,mass-mAE,/outline,thick=3
  print,median(mass-mAE),stdev(mass-mAE),median(mass-mAE)/stdev(mass-mAE)

  
  stop

END
