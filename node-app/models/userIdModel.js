const Auth = {
  userId: null,
  set id(value) {
    this.userId = value;
  },
  get get_userId() {
    return this.userId;
  },
};

module.exports = { Auth };