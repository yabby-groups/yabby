/** @jsx React.DOM */

var React = require('react');
var is_email = require('./util').is_email;

var file = require('./file');
var FileForm = file.FileForm;
var FileItem = file.FileItem;
var tweet = require('./tweet');
var TweetForm = tweet.TweetForm;
var TweetBox = tweet.TweetBox;
var TweetItem = tweet.TweetItem;
var TweetList = tweet.TweetList;

var LoginForm = React.createClass({
  handleSubmit: function(e) {
    e.preventDefault();
    var username = this.refs.username.getDOMNode().value.trim();
    var passwd = this.refs.passwd.getDOMNode().value.trim();
    if (!username) {
      notify('请输入用户名/邮箱', {hasCloseBtn: true, hasOkBtn: true});
      return;
    }
    if (!passwd) {
      notify('请输入密码', {hasCloseBtn: true, hasOkBtn: true});
      return;
    }
    this.props.onLoginSubmit({passwd: passwd, username: username});
  },
  render: function() {
    return (
      <form className="loginForm" onSubmit={this.handleSubmit}>
        <label htmlFor="username"> 用户名 </label>
        <input type="text" placeholder="用户名/邮箱" ref="username" />
        <label htmlFor="passwd"> 密码 </label>
        <input type="password" placeholder="密码" ref="passwd" />
        <label htmlFor="submit"> </label>
        <input type="submit" value="登录" />
      </form>
    )
  }
});


var PopupLogin = React.createClass({
  handleLogin: function(info) {
    var self = this;
    $.post('/auth', info, function(data) {
      if (data.user) {
        window.location.reload();
      } else {
        notify('用户名／密码不正确！', {hasCloseBtn: true, hasOkBtn: true});
      }
    });
  },
  render: function() {
    return (
      <div className="popup-inner">
        <span className="close">&times;</span>
        <h1> 登陆花苞儿 </h1>
        <LoginForm onLoginSubmit={this.handleLogin} />
        <div className="other">
          <div className="left">
            <a href="/forget_passwd">忘记密码</a>
          </div>
          <div className="right">
            还没有花苞儿账号? &nbsp;
            <a href="/register" onClick={this.props.onRegisterClick}>点击注册</a>
          </div>
        </div>
      </div>
    );
  }
});


var RegisterForm = React.createClass({
  handleSubmit: function(e) {
    e.preventDefault();
    var username = this.refs.username.getDOMNode().value.trim();
    var email = this.refs.email.getDOMNode().value.trim();
    var passwd = this.refs.passwd.getDOMNode().value.trim();
    var repasswd = this.refs.repasswd.getDOMNode().value.trim();
    if (!username) {
      notify('请输入用户名', {hasCloseBtn: true, hasOkBtn: true});
      return
    }
    if (!email) {
      notify('请输入邮箱地址', {hasCloseBtn: true, hasOkBtn: true});
      return
    }
    if (!is_email(email)) {
      notify('请输入正确的邮箱地址', {hasCloseBtn: true, hasOkBtn: true});
      return
    }
    if (!passwd) {
      notify('请输入密码', {hasCloseBtn: true, hasOkBtn: true});
      return
    }
    if (passwd !== repasswd) {
      notify('两次输入密码不一样', {hasCloseBtn: true, hasOkBtn: true});
      return
    }
    this.props.onRegisterSubmit({passwd: passwd, username: username, repasswd: repasswd, email: email});
  },
  render: function() {
    return (
      <form className="registerForm" onSubmit={this.handleSubmit}>
        <label htmlFor="username"> 用户名 </label>
        <input type="text" placeholder="用户名" ref="username" />
        <label htmlFor="email"> 邮箱 </label>
        <input type="text" placeholder="邮箱" ref="email" />
        <label htmlFor="passwd"> 密码 </label>
        <input type="password" placeholder="密码" ref="passwd" />
        <label htmlFor="repasswd"> 重复密码 </label>
        <input type="password" placeholder="重复密码" ref="repasswd" />
        <label htmlFor="submit"> </label>
        <input type="submit" value="注册" />
      </form>
    )
  }
});


var PopupRegister = React.createClass({
  handleRegister: function(info) {
    var self = this;
    $.post('/api/users/register', info, function(data) {
      if (data.user) {
        notify('注册成功', function() {
          window.location.reload();
        });
      } else {
        notify(data.msg, {hasCloseBtn: true, hasOkBtn: true});
      }
    });
  },
  render: function() {
    return (
      <div className="popup-inner popup-reg">
        <span className="close">&times;</span>
        <h1> 注册花苞儿 </h1>
        <RegisterForm onRegisterSubmit={this.handleRegister} />
        <div className="other">
          <div className="right">
            已有花苞儿账号? &nbsp;
            <a href="/login" onClick={this.props.onLoginClick}>登陆</a>
          </div>
        </div>
      </div>
    );
  }
});


var PopupBox = React.createClass({
  destory: function(evt) {
    if (evt.target.className === 'popup-outer' || evt.target.className === 'close') {
      umountPopup();
    }
  },
  getInitialState: function() {
    return {popupLogin: this.props.popupLogin, popupRegister: this.props.popupRegister}
  },
  handleLoginClick: function(evt) {
    if (evt) {
      evt.preventDefault();
    }
    this.setState({popupLogin: true, popupRegister: false});
  },
  handleRegisterClick: function(evt) {
    if (evt) {
      evt.preventDefault();
    }
    this.setState({popupLogin: false, popupRegister: true});
  },
  render: function() {
    var inner = null;
    if (this.state.popupLogin) {
      inner = <PopupLogin onRegisterClick={this.handleRegisterClick} />;
    } else if (this.state.popupRegister) {
      inner = <PopupRegister onLoginClick={this.handleLoginClick} />;
    } else {
      return false;
    }
    return (
      <div className="popup-outer" onClick={this.destory}>
        {inner}
      </div>
    );
  }
});


var NotifyBox = React.createClass({
  destory: function() {
    umountNotify();
  },
  handleClick: function() {
    if (this.props.onOKClick) {
      this.props.onOKClick();
    }
    umountNotify();
  },
  render: function() {
    var closeBtn = null;
    if (this.props.hasCloseBtn) {
      closeBtn = <span className="close" onClick={this.destory}>&times;</span>;
    }
    var okBtn = null;
    if (this.props.hasOkBtn) {
      okBtn = <button className="right" onClick={this.handleClick}>确定</button>;
    }
    return (
      <div className="popup-outer">
        <div className="popup-inner popup-notify">
          {closeBtn}
          <div className="title">
            提示:
          </div>
          <div className="message">
            {this.props.message}
            {okBtn}
          </div>
        </div>
      </div>
    );
  }
});


var InfoBox = React.createClass({
  handleLogout: function(evt) {
    var self = this;
    evt.preventDefault();
    $.get('/logout', function() {
      window.location.reload();
    });
  },
  handleLoginClick: function() {
    React.renderComponent(<PopupBox popupLogin={true} />, document.getElementById('popup'));
  },
  handleRegisterClick: function() {
    React.renderComponent(<PopupBox popupRegister={true} />, document.getElementById('popup'));
  },
  loadUserInfo: function() {
    var self = this;
    $.get('/api/users/me', function(data) {
      self.setState(data);
    });
  },
  getInitialState: function() {
    return {user: config.user};
  },
  componentDidMount: function() {
    if (!config.user) {
      // this.loadUserInfo();
    }
  },
  render: function() {
    if (!this.state.user || !this.state.user.user_id) {
      return (
        <div className="btns">
          <button onClick={this.handleLoginClick}>登陆</button>
          <button onClick={this.handleRegisterClick}>注册</button>
        </div>
      );
    }

    var user = this.state.user;

    var avatar;
    if (user.avatar) {
      avatar  = <FileItem file={user.avatar} />;
    } else {
      avatar = <img src='/static/images/human.png' />
    }
    return (
      <div className="btns">
        <div className='settings'>
          <a href="/favorite">
            {avatar}
            {user.username}
          </a>
        </div>
        <button onClick={this.handleLogout}> 登出 </button>
      </div>
    );
  }
});


var OneTweetBox = React.createClass({
  loadTweetFromServer: function() {
    var self = this;
    $.get(config.api, function(data) {
      self.setState(data);
    });
  },
  getInitialState: function() {
    return {tweet: config.tweet};
  },
  componentDidMount: function() {
  },
  render: function() {
    return (
      <div className="container">
        <TweetItem tweet={this.state.tweet} />
        <CommentBox />
      </div>
    );
  }
});


var CommentItem = React.createClass({
  getInitialState: function() {
    var comment = this.props.comment || {};
    var like_count = comment.like_count;
    var unlike_count = comment.unlike_count;
    return {like_count: like_count, unlike_count: unlike_count};
  },
  handleLike: function() {
    var self = this;
    if (!isLogin()) {return;}
    var commentId = this.props.comment.comment_id;
    var tweetId = this.props.comment.tweet_id;
    $.post("/api/tweets/" + tweetId + '/comments/' + commentId + '/like', function(data) {
      self.setState(data);
    });
  },
  render: function() {
    var comment = this.props.comment;
    var like_count = this.state.like_count;
    if (!like_count) {
      if (like_count !== 0) {
        like_count = comment.like_count || 0;
      }
    }

    var user = comment.user || {};

    var avatar;
    if (user.avatar) {
      avatar  = <FileItem file={user.avatar} />;
    } else {
      avatar = <img src='/static/images/human.png' />
    }

    return (
      <div className="comment">
        <div className="avatar">
          {avatar}
        </div>
        <h3 className="entry-title">
          <a href={"/users/" + user.user_id} title={user.username}>{user.username}</a>
        </h3>
        <div className="text">
          <p>{comment.text}</p>
        </div>
        <div className="right">
          <button className="like" onClick={this.handleLike}>{like_count}</button>
        </div>
      </div>
    );
  }
});


var CommentForm = React.createClass({
  handleSubmit: function(e) {
    e.preventDefault();
    var text = this.refs.text.getDOMNode().value.trim();
    if (!text) {
      return;
    }
    this.props.onCommentSubmit({text: text});
    this.refs.text.getDOMNode().value = '';
    return;
  },
  handleFocus: function() {
    $('.commentForm .placeholder').hide();
  },
  handleBlur: function() {
    var text = this.refs.text.getDOMNode().value.trim();
    if (!text) {
      $('.commentForm .placeholder').show();
    }
  },
  render: function() {
    if (!config.user || !config.user.user_id) {
      return <div className="comment"><h3>登陆后才可以评论哦。。。</h3></div>;
    }
    return (
      <form className="commentForm clearfix" onSubmit={this.handleSubmit}>
        <div className="placeholder">这里是评论！ </div>
        <textarea ref="text" onFocus={this.handleFocus} onBlur={this.handleBlur}> </textarea>
        <input type="submit" value="评论" />
      </form>
    );
  }
});


var CommentList = React.createClass({
  render: function() {
    var commentNodes = this.props.comments.map(function(comment, index) {
      return <CommentItem comment={comment} />
    });
    return (
      <div className="commentList">
      {commentNodes}
      </div>
    );
  }
});


var CommentBox = React.createClass({
  loadCommentsFromServer: function() {
    var self = this;
    var tweetId = this.props.tweetId;
    $.get(config.api + '/comments', function(data) {
      self.setState(data);
    });
  },
  getInitialState: function() {
    this.loadCommentsFromServer();
    return {comments: []};
  },
  componentDidMount: function() {
    this.loadCommentsFromServer();
  },
  handleComment: function(comment) {
    var self = this;
    $.post(config.api + '/comments', comment, function() {
      self.loadCommentsFromServer();
    })
  },
  render: function() {
    return (
      <div className="commentBox">
        <CommentList comments={this.state.comments} />
        <CommentForm onCommentSubmit={this.handleComment} />
      </div>
    );
  }
});


var UserInfo = React.createClass({
  handleSave: function(e) {
    e.preventDefault();
    var passwd = this.refs.passwd.getDOMNode().value.trim();
    var oldpasswd = this.refs.oldpasswd.getDOMNode().value.trim();
    var repasswd = this.refs.repasswd.getDOMNode().value.trim();
    if (!oldpasswd) {
      notify('请输入旧密码', {hasCloseBtn: true, hasOkBtn: true});
      return
    }
    if (!passwd) {
      notify('请输入新密码', {hasCloseBtn: true, hasOkBtn: true});
      return
    }
    if (passwd !== repasswd) {
      notify('两次输入密码不一样', {hasCloseBtn: true, hasOkBtn: true});
      return
    }
    $.post("/api/users/passwd", {
      passwd: passwd,
      oldpasswd: oldpasswd,
      repasswd: repasswd
    }, function(data) {
      if (data.err) {
        notify(data.msg, {hasCloseBtn: true, hasOkBtn: true});
      } else {
        notify('修改成功', {hasCloseBtn: true, hasOkBtn: true});
        this.refs.passwd.getDOMNode().value = '';
        this.refs.repasswd.getDOMNode().value = '';
        this.refs.oldpasswd.getDOMNode().value = '';
      }
    });
    return;
  },
  handleCancel: function(e) {
    e.preventDefault();
    var self = this;
    notify('确定取消', function () {
      self.refs.passwd.getDOMNode().value = '';
      self.refs.repasswd.getDOMNode().value = '';
      self.refs.oldpasswd.getDOMNode().value = '';
    });
  },
  render: function() {
    var user = config.user;
    if (user.avatar) {
      avatar  = <FileItem file={user.avatar} />;
    } else {
      avatar = <img src='/static/images/human.png' />
    }
    return (
      <div className="userInfo">
        <header className="entry-header">
          <h3 className="entry-title">
          修改个人资料
          </h3>
        </header>
        <label htmlFor="passwd"> 头像 </label>
        <div className="avatar">
            {avatar}
            <FileForm action="/api/avatar_upload"/>
        </div>
        <form className="userInfoForm">
          <label htmlFor="oldpasswd"> 旧密码 </label>
          <input type="password" ref="oldpasswd" />
          <label htmlFor="passwd"> 新密码 </label>
          <input type="password" ref="passwd" />
          <label htmlFor="submit"> </label>
          <label htmlFor="passwd"> 重复新密码 </label>
          <input type="password" ref="repasswd" />
          <div htmlFor="submit" className="btns">
            <button onClick={this.handleSave}>保存</button>
            <button className="cancel" onClick={this.handleCancel}>取消</button>
          </div>
        </form>
      </div>
    );
  }
});


function render_tweets() {
  React.renderComponent(
    <TweetBox />,
    document.getElementById("content")
  );
}

function render_info() {
  React.renderComponent(
    <InfoBox />,
    document.getElementById("info")
  );
}


function render_tweet() {
  React.renderComponent(
    <OneTweetBox />,
    document.getElementById("content")
  );
}


function render_new_tweet() {
  React.renderComponent(
    <div className="newTweetBox">
      <FileForm />
      <TweetForm />
    </div>,
    document.getElementById("content"),
    function() {
      $(".fileForm").ajaxForm(function(result) {
        if (result.file) {
          $(".choose-file").text("上传完成");
          $("#tweetFile").val(result.file.file_id);
        } else {
          $(".choose-file").text("上传失败");
        }
        umountNotify();
      });
    }
  );
}

function render_edit_avatar() {
  React.renderComponent(
    <UserInfo />,
    document.getElementById("content"),
    function() {
      $(".fileForm").ajaxForm(function(result) {
        if (result.avatar) {
          $(".choose-file").text("上传完成");
          var file = result.avatar;
          $(".avatar").html('<img src=' + config.img_host + '/' + file.file_bucket + '/' + file.file_key + ' />');
        } else {
          $(".choose-file").text("上传失败");
        }
        umountNotify();
      });
    }
  );
}

var isLogin = function() {
  if (config.user && config.user.user_id) {
    return true;
  }
  React.renderComponent(<PopupBox popupLogin={true} />, document.getElementById('popup'));
  return false;
};

var umountPopup = function(evt) {
  React.unmountComponentAtNode(document.getElementById('popup'));
};

var notify = function(message, opts, callback) {
  if (typeof opts === 'function') {
    callback = opts;
    opts = {hasOkBtn: true, hasCloseBtn: true};
  }
  opts = opts || {};
  React.renderComponent(<NotifyBox onOKClick={callback} message={message} hasCloseBtn={opts.hasCloseBtn} hasOkBtn={opts.hasOkBtn} />,
      document.getElementById('popup-notify'));
};

var umountNotify = function(evt) {
  React.unmountComponentAtNode(document.getElementById('popup-notify'));
};

window.render_tweets = render_tweets;
window.render_info = render_info;
window.render_tweet = render_tweet;
window.render_new_tweet = render_new_tweet;
window.render_edit_avatar = render_edit_avatar;
