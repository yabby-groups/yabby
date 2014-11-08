/** @jsx React.DOM */

var React = require('react');

var FileItem = exports.FileItem = React.createClass({
  render: function() {
    var file = this.props.file || {};
    return <img src={config.img_host + '/' + file.file_bucket + '/' + file.file_key} />;
  }
});


var FileForm = exports.FileForm = React.createClass({
  getInitialState: function() {
    return {};
  },
  handleFile: function() {
    if (!isLogin()) {return;}
    $(".choose-file").text("正在上传");
    notify('正在上传图片...')
    $(this.refs.fileForm.getDOMNode()).submit();
  },
  handleClick: function() {
    if (!isLogin()) {return;}
    $(this.refs.file.getDOMNode()).click();
  },
  render: function() {
    var action = this.props.action || "/api/upload"
    return (
      <div className="fileForm">
        <button className="choose-file" onClick={this.handleClick}> 选择图片 </button>
        <form ref="fileForm" encType="multipart/form-data" method="POST" action={action}>
          <input ref="file" type="file" name="file" onChange={this.handleFile} />
        </form>
      </div>
    );
  }
});
