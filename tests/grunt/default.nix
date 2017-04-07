# This file has been generated by node2nix 1.3.0. Do not edit!

{pkgs ? import <nixpkgs> {
    inherit system;
  }, system ? builtins.currentSystem, nodejs ? pkgs."nodejs-4_x"}:

let
  globalBuildInputs = pkgs.lib.attrValues (import ./supplement.nix {
    inherit nodeEnv;
    inherit (pkgs) fetchurl fetchgit;
  });
  nodeEnv = import ../../nix/node-env.nix {
    inherit (pkgs) stdenv python2 utillinux runCommand writeTextFile;
    inherit nodejs;
  };
in
import ./node-packages.nix {
  inherit (pkgs) fetchurl fetchgit;
  inherit nodeEnv globalBuildInputs;
}