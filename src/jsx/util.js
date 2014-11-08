/** @jsx React.DOM */

var is_email = exports.is_email = function(string) {
  return /^[a-z]([a-z0-9]*[-_]?[a-z0-9]+)*@([a-z0-9]*[-_]?[a-z0-9]+)+[\.][a-z]{2,3}([\.][a-z]{2})?$/i.exec(string);
};
